import random
from sys import exit
import pygame
from pygame.locals import *
import os
import copy

score = 0
best = 0
update_flag = False
box_size = 50
box_gap  = 5
top_of_screen = 100
bottom_of_screen = 30
left_of_screen = 20
screen_width  = box_size * 4 + box_gap * 5 + left_of_screen * 2
screen_height = top_of_screen + box_gap * 5 + box_size * 4 + left_of_screen + bottom_of_screen
screen = pygame.display.set_mode((screen_width, screen_height), 0, 32)
pygame.init()
pygame.display.set_caption("2048")
background = pygame.image.load('background.jpg').convert()
#reset = pygame.image.load('reset.jpg').convert()

OLDLACE    = pygame.color.THECOLORS["oldlace"]
IVORY   = pygame.color.THECOLORS["ivory3"]
BLACK   = pygame.color.THECOLORS["black"]
RED     = pygame.color.THECOLORS["red"]
RED2    = pygame.color.THECOLORS["red2"]
DARKGOLD  = pygame.color.THECOLORS["darkgoldenrod1"]
GOLD    =  pygame.color.THECOLORS["gold"]
GRAY    = pygame.color.THECOLORS["gray41"]
CHOCOLATE = pygame.color.THECOLORS["chocolate"]
CHOCOLATE1 = pygame.color.THECOLORS["chocolate1"]
CORAL   = pygame.color.THECOLORS["coral"]
CORAL2  = pygame.color.THECOLORS["coral2"]
ORANGED = pygame.color.THECOLORS["orangered"]
ORANGED2 = pygame.color.THECOLORS["orangered2"]
DARKORANGE = pygame.color.THECOLORS["darkorange"]
DARKORANGE2 = pygame.color.THECOLORS["darkorange2"]
FORESTGREEN = pygame.color.THECOLORS['forestgreen']


class Rect:
    
    def __init__(self, topleft, widthheight, text, frontcolor=BLACK,backcolor = (0,0,0),font_height=0):
        self.topleft = topleft
        self.widthheight = widthheight
        self.text = text
        self.frontcolor = frontcolor
        self.backcolor = backcolor
        self.font_height=font_height
        
    def write(self, color, height = 14):   
        font = pygame.font.Font("LucidaSansRegular.ttf", height)
        text_c = font.render(self.text, True, color)
        text_a = text_c.convert_alpha()
        self.text = text_a

    def render(self, surface):
        x, y = self.topleft
        width,height = self.widthheight
        pygame.draw.rect(surface, self.backcolor, (x, y, width, height))
        if self.font_height == 0 :
            self.font_height  = int(height * 0.35)
        self.write(self.frontcolor,self.font_height)
        text_rect    = self.text.get_rect()
        text_rect.center = (x + width / 2, y + height / 2)
        surface.blit(self.text, text_rect)

        
def init ():
    global best
    mtr = [[0 for i in range(4)] for j in range(4)]  
    ran_pos = random.sample(range(16), 2)
    mtr[ran_pos[0]//4][ran_pos[0]%4] = 2
    mtr[ran_pos[1]//4][ran_pos[1]%4] = 4
    with open (os.path.join(os.getcwd(),'best.txt'), 'r') as f:
        try :
            best = int(f.readline())
        except :
            best = 0
    f.close()
    return mtr

     
def draw_box():
    global mtr
    global score
    
    #16个正方格  
    colors = {0:(192, 192, 192), 2:(176, 224, 230), 4:(127, 255, 212), 8:(135, 206, 235), 16:(64, 224, 208),
              32:(0, 255, 255), 64:(0, 201, 87), 128:(50, 205, 50), 256:(34, 139, 34),
              512:(0, 255, 127), 1024:(48, 128, 20), 2048:(190, 0, 0), 4096:(65, 105, 255),
              8192:(8, 46, 84), 16384:(11, 23, 70), 32768:(25, 25, 112), 65536:(0, 0, 255)}
    x, y = left_of_screen, top_of_screen
    size = box_size * 4 + box_gap * 5
    pygame.draw.rect(screen, BLACK, (x, y, size, size))
    x, y = x + box_gap, y + box_gap
    for i in range(4):
        for j in range(4):
            idx = mtr[i][j]
            if idx == 0:
                text = ""
            else:
                text = str(idx)
            if idx > 65536: idx = 65536
            color = colors[idx]
            box = Rect((x, y),(box_size,box_size), text, BLACK,color)
            box.render(screen)
            x += box_size + box_gap
        x = left_of_screen + box_gap
        y += box_size + box_gap


def refh_img():
    global score
    screen.blit(background, (0,0))

    def write_text (text = '', ttf = 'LucidaSansRegular.ttf', color = BLACK, height = 14):   
        font = pygame.font.Font(ttf, height)
        text_c = font.render(text, True, color)
        text_c = text_c.convert_alpha()
        return text_c
    
    #重置
    
    x = left_of_screen+10
    y = left_of_screen//2 + 15
    retry = Rect((x,y),(60,30), 'Reset', BLACK, (255,255,15), 16)
    retry.render(screen)

    #分数
    screen.blit(write_text(u"Score", color=CHOCOLATE, height=16), (left_of_screen+105, left_of_screen//2 + 5))
    x = left_of_screen+100
    y = left_of_screen//2 + 30
    scores = Rect((x,y),(60,20), str(score), BLACK, (255,202,172), 14)
    scores.render(screen)

    #最高分
    screen.blit(write_text(u"Best", color=CHOCOLATE, height=16), (left_of_screen+175, left_of_screen//2 + 5))
    
    x = left_of_screen+165
    y = left_of_screen//2 + 30
    bscore = Rect((x,y), (60,20), str(best), BLACK, (255,202,172), 14)
    bscore.render(screen)
    #画4*4矩阵
    draw_box()


def move(mtr, dirct):
  global score
  global best
  global update_flag
  update_flag = False
  mtr_source = copy.deepcopy(mtr)
  if dirct == 0:  # left
    for i in range(4):
      for j in range(1, 4):
        for k in range(j,0,-1):
          if mtr[i][k - 1] == 0 :
            mtr[i][k - 1] = mtr[i][k]
            mtr[i][k] = 0
          elif mtr[i][k - 1] == mtr[i][k]:
            mtr[i][k - 1] *= 2
            mtr[i][k] = 0
            score += mtr[i][k - 1]
            
  elif dirct == 1:  # down
    for j in range(4):
      for i in range(0,3):
        for k in range(3,i,-1):
          if mtr[k][j] == 0 :
            mtr[k][j] = mtr[k-1][j]
            mtr[k-1][j] = 0
          elif mtr[k][j]==mtr[k-1][j]:
            mtr[k][j]*=2
            mtr[k-1][j]=0
            score += mtr[k][j]
   
  elif dirct == 2:  # up
    for j in range(4):
      for i in range(1,4):
        for k in range(i,0,-1):
          if mtr[k-1][j] == 0:
            mtr[k-1][j]=mtr[k][j]
            mtr[k][j]=0
          elif mtr[k-1][j]==mtr[k][j]:
            mtr[k-1][j]*=2
            mtr[k][j]=0
            score += mtr[k-1][j]
            
  elif dirct == 3:  # right
    for i in range(4):
      for j in range(0,3):
        for k in range(3,j,-1):
           if mtr[i][k] == 0:
            mtr[i][k] = mtr[i][k-1]
            mtr[i][k-1]=0
           elif mtr[i][k] ==mtr[i][k-1]:
            mtr[i][k]*=2
            mtr[i][k-1]=0
            score += mtr[i][k]
  get_best()
  for i in range(4):
      if mtr_source[i] != mtr[i] :
          update_flag = True
          break
  
  return score


def update(mtr):
  ran_pos=[]
  ran_num=[2,4]

  for i in range(4):
    for j in range(4):
      if mtr[i][j] == 0:
         ran_pos.append(4*i+j)
  if len(ran_pos) > 0:
    k=random.choice(ran_pos)
    n=random.choice(ran_num)
    mtr[k//4][k%4]=n


def get_best():
    global score
    global best
    if score > best:
        best = score
        with open (os.path.join(os.getcwd(), 'best.txt'), 'w+') as f:
            f.write(str(best))
        f.close()
    return best


def go_on(mtr):
    if 2048 in mtr:
        print ('Greate! You Win! Your score is ',score)
        pygame.quit()
        exit()
    for i in range(4):
        for j in range(4):
            if mtr[i][j] == 0 :
                return True
            if i < 3 and mtr[i][j] == mtr[i+1][j]:
                return True
            if j < 3 and mtr[i][j] == mtr[i][j+1]:
                return True
    return False


if __name__ == '__main__':
    mtr = init()
    refh_img()

    while True:
        for event in pygame.event.get():
            if event.type == QUIT or (event.type == KEYUP and event.key == K_ESCAPE):
                pygame.quit()
                exit()
            if event.type == MOUSEBUTTONDOWN and \
                     left_of_screen+10<=event.pos[0]< left_of_screen+64 and \
                     left_of_screen//2 + 15<=event.pos[1]<=left_of_screen//2 + 50 :
                     score = 0
                     mtr = init ()
            if go_on(mtr):
                old_score = score
                if event.type == KEYUP and event.key == K_UP:
                    
                    score = move(mtr, 2)
                    ##(已删)如果key为上、左、右，没有合并值，则不会新加入元素。
                    if update_flag == True :
                        update(mtr)
                elif event.type == KEYUP and event.key == K_DOWN:
                    score = move(mtr, 1)
                    if update_flag == True :
                        update(mtr)                   
                elif event.type == KEYUP and event.key == K_LEFT:
                    score = move(mtr, 0)
                    if update_flag == True :
                        update(mtr)
                elif event.type == KEYUP and event.key == K_RIGHT:
                    score = move(mtr, 3)
                    if update_flag == True :
                        update(mtr)
                
            elif go_on(mtr) == False:
                pass
            refh_img()
            pygame.display.update()
    


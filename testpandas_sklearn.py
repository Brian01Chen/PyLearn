import pandas as pd
from sklearn_pandas import DataFrameMapper
from sklearn.preprocessing import *


testdata = pd.DataFrame({'pet': ['cat', 'dog', 'dog', 'fish', 'cat', 'dog', 'cat', 'fish'],
                         'age': [4., 6, 3, 3, 2, 3, 5, 4],
                         'salary':  [90, 24, 44, 27, 32, 59, 36, 27]}
                        )
mapper = DataFrameMapper([('pet', LabelBinarizer()),
                          (['age'], StandardScaler())])
td = mapper.fit_transform(testdata)

print (td)

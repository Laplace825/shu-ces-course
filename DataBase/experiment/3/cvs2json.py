import pandas as pd

# csv to json
csv = pd.read_csv('./us_births_2016_2021.csv')

# csv column name
# if any name is like `Average Age of`, replace the space with `_`
# if any name is like `Mother (yeaer)`, delete the `(` and `)`
csv_column_name = csv.columns
json_names = []
for name in csv_column_name:
    name = name.replace(' ', '_')
    name = name.replace('(', '')
    name = name.replace(')', '')
    json_names.append(name)
csv.rename(columns=dict(zip(csv_column_name, json_names)), inplace=True)

print(csv.columns)

# save to json
csv.to_json('./us_births_2016_2021.json', orient='records')


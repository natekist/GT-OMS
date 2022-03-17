"""
cse6242 s21
wrangling.py - utilities to supply data to the templates.

This file contains a pair of functions for retrieving and manipulating data
that will be supplied to the template for generating the table. """
import csv
from operator import itemgetter

def username():
    return 'nkistler3'

def data_wrangling():
    with open('data/movies.csv', 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        table = list()
        # Feel free to add any additional variables
        ...
        
        # Read in the header
        for header in reader:
            break

        count = 0
        # Read in each row
        for row in reader:
            row[2] = float(row[2])
            table.append(row)
            count += 1
            if count == 100:
                break
            
            # Only read first 100 data rows - [2 points] Q5.a
            ...
        
        # Order table by the last column - [3 points] Q5.b
        table = sorted(table, key=itemgetter(2), reverse=True)

        updated_table = []

        for row in table:
            row[2] = str(row[2])
            updated_table.append(row)

    return header, updated_table


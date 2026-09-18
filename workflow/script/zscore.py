# coding: utf-8

import pandas

# Load counts
df = pandas.read_csv(
    snakemake.input[0],
    sep=",",
    header=0,
    index_col=0,
)
print(df.head())

# Compute z-score
numeric = df.select_dtypes(include="number")
zscore = (numeric - numeric.mean()) / numeric.std(ddof=0)
print(zscore.head())

# Save results
zscore.to_csv(snakemake.output[0])

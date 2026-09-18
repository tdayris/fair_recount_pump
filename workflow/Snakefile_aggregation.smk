include: "rules/common.smk"
include: "rules/aggregate_counts.smk"

rule target:
    return {
        "aggregated": "results/zscore_aggregated_counts.csv",
    }

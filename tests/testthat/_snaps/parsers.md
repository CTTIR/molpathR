# mp_read_vcf text parser output is a stable regression lock

    {
      "type": "list",
      "attributes": {
        "row.names": {
          "type": "integer",
          "attributes": {},
          "value": [1, 2]
        },
        "names": {
          "type": "character",
          "attributes": {},
          "value": ["chrom", "pos", "id", "ref", "alt", "qual", "filter", "info"]
        },
        "class": {
          "type": "character",
          "attributes": {},
          "value": ["data.frame"]
        }
      },
      "value": [
        {
          "type": "character",
          "attributes": {},
          "value": ["chr1", "chr3"]
        },
        {
          "type": "integer",
          "attributes": {},
          "value": [12345, 999]
        },
        {
          "type": "character",
          "attributes": {},
          "value": ["rs1", "."]
        },
        {
          "type": "character",
          "attributes": {},
          "value": ["A", "GG"]
        },
        {
          "type": "character",
          "attributes": {},
          "value": ["T", "G"]
        },
        {
          "type": "double",
          "attributes": {},
          "value": [100, 40]
        },
        {
          "type": "character",
          "attributes": {},
          "value": ["PASS", "LowQual"]
        },
        {
          "type": "character",
          "attributes": {},
          "value": ["DP=50;AF=0.3", "DP=12"]
        }
      ]
    }


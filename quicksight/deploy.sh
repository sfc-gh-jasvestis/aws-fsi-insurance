#!/usr/bin/env bash
set -euo pipefail

# QuickSight Deployment Script for APJ Insurance Demo
# Requires: AWS_ACCOUNT_ID env var, aws CLI, QuickSight Enterprise active
# Usage: bash quicksight/deploy.sh

REGION="us-west-2"
ACCT="${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID first}"
DS_ID="insurance-snowflake-ds-v3"
DS_ARN="arn:aws:quicksight:${REGION}:${ACCT}:datasource/${DS_ID}"

# Discover the QuickSight admin user ARN
QS_USER_ARN=$(aws quicksight list-users --aws-account-id "$ACCT" --namespace default --region "$REGION" \
  --query 'UserList[?Role==`ADMIN` || Role==`ADMIN_PRO`]|[0].Arn' --output text)
echo "QuickSight admin: $QS_USER_ARN"

# ── Helper ────────────────────────────────────────────────────────────────────

fail() { echo "FAILED: $1"; exit 1; }
ok()   { echo "  ✓ $1"; }

# ── Step 1: Snowflake service user + network policy (done in Snowflake) ───────
echo ""
echo "=== Step 1: Verify data source ==="

STATUS=$(aws quicksight describe-data-source --aws-account-id "$ACCT" --region "$REGION" \
  --data-source-id "$DS_ID" --query 'DataSource.Status' --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$STATUS" != "CREATION_SUCCESSFUL" ]; then
  echo "Data source '$DS_ID' status: $STATUS"
  echo "Create the data source first (Snowflake connector with QUICKSIGHT_USER)."
  echo "The plan covers this in Steps 5.1-5.2."
  exit 1
fi
ok "Data source $DS_ID is healthy"

# ── Step 2: Create datasets ───────────────────────────────────────────────────
echo ""
echo "=== Step 2: Create datasets ==="

# Dataset 1: Claims
aws quicksight create-data-set \
  --aws-account-id "$ACCT" --region "$REGION" \
  --data-set-id "insurance-claims-ds" \
  --name "APJ Insurance Claims" \
  --import-mode DIRECT_QUERY \
  --physical-table-map "$(cat <<EOJSON
{
  "claims-physical": {
    "CustomSql": {
      "DataSourceArn": "${DS_ARN}",
      "Name": "Claims",
      "SqlQuery": "SELECT CLAIM_ID, CLAIM_TYPE, POLICY_TYPE, POLICY_NUMBER, STATUS, COUNTRY, CITY, FIRST_NAME, LAST_NAME, FILING_DATE, CLAIM_AMOUNT, COVERAGE_LIMIT, DEDUCTIBLE, PREMIUM, AI_DECISION, AI_REASONING, COUNTRY_GDP_PER_CAPITA, COUNTRY_INSURANCE_PENETRATION, COUNTRY_DISASTER_EXPOSURE FROM INSURANCE_DEMO_DB.CURATED.CLAIMS",
      "Columns": [
        {"Name": "CLAIM_ID", "Type": "STRING"},
        {"Name": "CLAIM_TYPE", "Type": "STRING"},
        {"Name": "POLICY_TYPE", "Type": "STRING"},
        {"Name": "POLICY_NUMBER", "Type": "STRING"},
        {"Name": "STATUS", "Type": "STRING"},
        {"Name": "COUNTRY", "Type": "STRING"},
        {"Name": "CITY", "Type": "STRING"},
        {"Name": "FIRST_NAME", "Type": "STRING"},
        {"Name": "LAST_NAME", "Type": "STRING"},
        {"Name": "FILING_DATE", "Type": "DATETIME"},
        {"Name": "CLAIM_AMOUNT", "Type": "DECIMAL"},
        {"Name": "COVERAGE_LIMIT", "Type": "DECIMAL"},
        {"Name": "DEDUCTIBLE", "Type": "DECIMAL"},
        {"Name": "PREMIUM", "Type": "DECIMAL"},
        {"Name": "AI_DECISION", "Type": "STRING"},
        {"Name": "AI_REASONING", "Type": "STRING"},
        {"Name": "COUNTRY_GDP_PER_CAPITA", "Type": "DECIMAL"},
        {"Name": "COUNTRY_INSURANCE_PENETRATION", "Type": "DECIMAL"},
        {"Name": "COUNTRY_DISASTER_EXPOSURE", "Type": "DECIMAL"}
      ]
    }
  }
}
EOJSON
)" \
  --permissions "[{\"Principal\":\"${QS_USER_ARN}\",\"Actions\":[\"quicksight:DescribeDataSet\",\"quicksight:DescribeDataSetPermissions\",\"quicksight:PassDataSet\",\"quicksight:DescribeIngestion\",\"quicksight:ListIngestions\",\"quicksight:UpdateDataSet\",\"quicksight:DeleteDataSet\",\"quicksight:CreateIngestion\",\"quicksight:CancelIngestion\",\"quicksight:UpdateDataSetPermissions\"]}]" \
  2>&1 && ok "Dataset: insurance-claims-ds" || fail "Dataset: insurance-claims-ds"

# Dataset 2: APAC Country Risk
aws quicksight create-data-set \
  --aws-account-id "$ACCT" --region "$REGION" \
  --data-set-id "insurance-apac-country-risk" \
  --name "APJ Country Risk (World Bank)" \
  --import-mode DIRECT_QUERY \
  --physical-table-map "$(cat <<EOJSON
{
  "risk-physical": {
    "CustomSql": {
      "DataSourceArn": "${DS_ARN}",
      "Name": "APAC Country Risk",
      "SqlQuery": "SELECT COUNTRY, COUNTRY_CODE, GDP_PER_CAPITA, INSURANCE_PENETRATION, NATURAL_DISASTER_EXPOSURE, POPULATION, DISASTER_DISPLACED_PERSONS FROM INSURANCE_DEMO_DB.CURATED.APAC_COUNTRY_RISK",
      "Columns": [
        {"Name": "COUNTRY", "Type": "STRING"},
        {"Name": "COUNTRY_CODE", "Type": "STRING"},
        {"Name": "GDP_PER_CAPITA", "Type": "DECIMAL"},
        {"Name": "INSURANCE_PENETRATION", "Type": "DECIMAL"},
        {"Name": "NATURAL_DISASTER_EXPOSURE", "Type": "DECIMAL"},
        {"Name": "POPULATION", "Type": "DECIMAL"},
        {"Name": "DISASTER_DISPLACED_PERSONS", "Type": "DECIMAL"}
      ]
    }
  }
}
EOJSON
)" \
  --permissions "[{\"Principal\":\"${QS_USER_ARN}\",\"Actions\":[\"quicksight:DescribeDataSet\",\"quicksight:DescribeDataSetPermissions\",\"quicksight:PassDataSet\",\"quicksight:DescribeIngestion\",\"quicksight:ListIngestions\",\"quicksight:UpdateDataSet\",\"quicksight:DeleteDataSet\",\"quicksight:CreateIngestion\",\"quicksight:CancelIngestion\",\"quicksight:UpdateDataSetPermissions\"]}]" \
  2>&1 && ok "Dataset: insurance-apac-country-risk" || fail "Dataset: insurance-apac-country-risk"

# Dataset 3: Extracted Adjuster Notes
aws quicksight create-data-set \
  --aws-account-id "$ACCT" --region "$REGION" \
  --data-set-id "insurance-extracted-notes" \
  --name "AI Extracted Adjuster Notes" \
  --import-mode DIRECT_QUERY \
  --physical-table-map "$(cat <<EOJSON
{
  "notes-physical": {
    "CustomSql": {
      "DataSourceArn": "${DS_ARN}",
      "Name": "Extracted Notes",
      "SqlQuery": "SELECT * FROM INSURANCE_DEMO_DB.AI.EXTRACTED_ADJUSTER_NOTES",
      "Columns": [
        {"Name": "FILE_NAME", "Type": "STRING"},
        {"Name": "CLAIM_ID", "Type": "STRING"},
        {"Name": "ADJUSTER_NAME", "Type": "STRING"},
        {"Name": "INSPECTION_DATE", "Type": "STRING"},
        {"Name": "DAMAGE_ASSESSMENT", "Type": "STRING"},
        {"Name": "ESTIMATED_AMOUNT", "Type": "DECIMAL"},
        {"Name": "RECOMMENDATION", "Type": "STRING"}
      ]
    }
  }
}
EOJSON
)" \
  --permissions "[{\"Principal\":\"${QS_USER_ARN}\",\"Actions\":[\"quicksight:DescribeDataSet\",\"quicksight:DescribeDataSetPermissions\",\"quicksight:PassDataSet\",\"quicksight:DescribeIngestion\",\"quicksight:ListIngestions\",\"quicksight:UpdateDataSet\",\"quicksight:DeleteDataSet\",\"quicksight:CreateIngestion\",\"quicksight:CancelIngestion\",\"quicksight:UpdateDataSetPermissions\"]}]" \
  2>&1 && ok "Dataset: insurance-extracted-notes" || fail "Dataset: insurance-extracted-notes"

# ── Validate datasets ─────────────────────────────────────────────────────────
echo ""
echo "=== Validate datasets ==="
for DS in insurance-claims-ds insurance-apac-country-risk insurance-extracted-notes; do
  S=$(aws quicksight describe-data-set --aws-account-id "$ACCT" --region "$REGION" \
    --data-set-id "$DS" --query 'DataSet.Name' --output text 2>/dev/null || echo "MISSING")
  echo "  $DS → $S"
done

# ── Step 3: Create analysis with full visual definitions ──────────────────────
echo ""
echo "=== Step 3: Create analysis ==="

CLAIMS_DS_ARN="arn:aws:quicksight:${REGION}:${ACCT}:dataset/insurance-claims-ds"
RISK_DS_ARN="arn:aws:quicksight:${REGION}:${ACCT}:dataset/insurance-apac-country-risk"

# Write the analysis definition to a temp file (too large for inline)
ANALYSIS_DEF=$(mktemp)
cat > "$ANALYSIS_DEF" <<EOJSON
{
  "AwsAccountId": "${ACCT}",
  "AnalysisId": "insurance-apj-analysis",
  "Name": "APJ Insurance Claims Analysis",
  "Permissions": [{
    "Principal": "${QS_USER_ARN}",
    "Actions": [
      "quicksight:RestoreAnalysis",
      "quicksight:UpdateAnalysisPermissions",
      "quicksight:DeleteAnalysis",
      "quicksight:DescribeAnalysisPermissions",
      "quicksight:QueryAnalysis",
      "quicksight:DescribeAnalysis",
      "quicksight:UpdateAnalysis"
    ]
  }],
  "Definition": {
    "DataSetIdentifierDeclarations": [
      {"Identifier": "claims", "DataSetArn": "${CLAIMS_DS_ARN}"},
      {"Identifier": "apac_risk", "DataSetArn": "${RISK_DS_ARN}"}
    ],
    "Sheets": [
      {
        "SheetId": "claims-pipeline",
        "Name": "Claims Pipeline",
        "Visuals": [
          {
            "KPIVisual": {
              "VisualId": "total-claims-kpi",
              "Title": {"Visibility": "VISIBLE", "FormatText": {"PlainText": "Total Claims"}},
              "ChartConfiguration": {
                "FieldWells": {
                  "Values": [{
                    "CategoricalMeasureField": {
                      "FieldId": "total-claims-val",
                      "Column": {"DataSetIdentifier": "claims", "ColumnName": "CLAIM_ID"},
                      "AggregationFunction": "DISTINCT_COUNT"
                    }
                  }]
                }
              }
            }
          },
          {
            "KPIVisual": {
              "VisualId": "total-claimed-kpi",
              "Title": {"Visibility": "VISIBLE", "FormatText": {"PlainText": "Total Amount Claimed"}},
              "ChartConfiguration": {
                "FieldWells": {
                  "Values": [{
                    "NumericalMeasureField": {
                      "FieldId": "total-claimed-val",
                      "Column": {"DataSetIdentifier": "claims", "ColumnName": "CLAIM_AMOUNT"},
                      "AggregationFunction": {"SimpleNumericalAggregation": "SUM"}
                    }
                  }]
                }
              }
            }
          },
          {
            "KPIVisual": {
              "VisualId": "avg-claim-kpi",
              "Title": {"Visibility": "VISIBLE", "FormatText": {"PlainText": "Average Claim"}},
              "ChartConfiguration": {
                "FieldWells": {
                  "Values": [{
                    "NumericalMeasureField": {
                      "FieldId": "avg-claim-val",
                      "Column": {"DataSetIdentifier": "claims", "ColumnName": "CLAIM_AMOUNT"},
                      "AggregationFunction": {"SimpleNumericalAggregation": "AVERAGE"}
                    }
                  }]
                }
              }
            }
          },
          {
            "BarChartVisual": {
              "VisualId": "claims-by-type",
              "Title": {"Visibility": "VISIBLE", "FormatText": {"PlainText": "Claims by Type"}},
              "ChartConfiguration": {
                "FieldWells": {
                  "BarChartAggregatedFieldWells": {
                    "Category": [{
                      "CategoricalDimensionField": {
                        "FieldId": "type-dim",
                        "Column": {"DataSetIdentifier": "claims", "ColumnName": "CLAIM_TYPE"}
                      }
                    }],
                    "Values": [{
                      "CategoricalMeasureField": {
                        "FieldId": "type-count",
                        "Column": {"DataSetIdentifier": "claims", "ColumnName": "CLAIM_ID"},
                        "AggregationFunction": "COUNT"
                      }
                    }]
                  }
                },
                "Orientation": "HORIZONTAL",
                "BarsArrangement": "CLUSTERED"
              }
            }
          },
          {
            "BarChartVisual": {
              "VisualId": "claims-by-status",
              "Title": {"Visibility": "VISIBLE", "FormatText": {"PlainText": "Claims by Status"}},
              "ChartConfiguration": {
                "FieldWells": {
                  "BarChartAggregatedFieldWells": {
                    "Category": [{
                      "CategoricalDimensionField": {
                        "FieldId": "status-dim",
                        "Column": {"DataSetIdentifier": "claims", "ColumnName": "STATUS"}
                      }
                    }],
                    "Values": [{
                      "CategoricalMeasureField": {
                        "FieldId": "status-count",
                        "Column": {"DataSetIdentifier": "claims", "ColumnName": "CLAIM_ID"},
                        "AggregationFunction": "COUNT"
                      }
                    }]
                  }
                },
                "Orientation": "HORIZONTAL",
                "BarsArrangement": "CLUSTERED"
              }
            }
          },
          {
            "BarChartVisual": {
              "VisualId": "claims-by-country",
              "Title": {"Visibility": "VISIBLE", "FormatText": {"PlainText": "Claims by Country"}},
              "ChartConfiguration": {
                "FieldWells": {
                  "BarChartAggregatedFieldWells": {
                    "Category": [{
                      "CategoricalDimensionField": {
                        "FieldId": "country-dim",
                        "Column": {"DataSetIdentifier": "claims", "ColumnName": "COUNTRY"}
                      }
                    }],
                    "Values": [{
                      "NumericalMeasureField": {
                        "FieldId": "country-amount",
                        "Column": {"DataSetIdentifier": "claims", "ColumnName": "CLAIM_AMOUNT"},
                        "AggregationFunction": {"SimpleNumericalAggregation": "SUM"}
                      }
                    }]
                  }
                },
                "Orientation": "HORIZONTAL",
                "BarsArrangement": "CLUSTERED"
              }
            }
          },
          {
            "TableVisual": {
              "VisualId": "top-claims-table",
              "Title": {"Visibility": "VISIBLE", "FormatText": {"PlainText": "Top Claims by Amount"}},
              "ChartConfiguration": {
                "FieldWells": {
                  "TableAggregatedFieldWells": {
                    "GroupBy": [
                      {"CategoricalDimensionField": {"FieldId": "tbl-claim-id", "Column": {"DataSetIdentifier": "claims", "ColumnName": "CLAIM_ID"}}},
                      {"CategoricalDimensionField": {"FieldId": "tbl-type", "Column": {"DataSetIdentifier": "claims", "ColumnName": "CLAIM_TYPE"}}},
                      {"CategoricalDimensionField": {"FieldId": "tbl-country", "Column": {"DataSetIdentifier": "claims", "ColumnName": "COUNTRY"}}},
                      {"CategoricalDimensionField": {"FieldId": "tbl-status", "Column": {"DataSetIdentifier": "claims", "ColumnName": "STATUS"}}}
                    ],
                    "Values": [
                      {"NumericalMeasureField": {"FieldId": "tbl-amount", "Column": {"DataSetIdentifier": "claims", "ColumnName": "CLAIM_AMOUNT"}, "AggregationFunction": {"SimpleNumericalAggregation": "SUM"}}}
                    ]
                  }
                },
                "SortConfiguration": {
                  "RowSort": [{"FieldSort": {"FieldId": "tbl-amount", "Direction": "DESC"}}]
                }
              }
            }
          }
        ],
        "Layouts": [{
          "Configuration": {
            "GridLayout": {
              "Elements": [
                {"ElementId": "total-claims-kpi",  "ElementType": "VISUAL", "ColumnIndex": 0,  "ColumnSpan": 12, "RowIndex": 0,  "RowSpan": 6},
                {"ElementId": "total-claimed-kpi",  "ElementType": "VISUAL", "ColumnIndex": 12, "ColumnSpan": 12, "RowIndex": 0,  "RowSpan": 6},
                {"ElementId": "avg-claim-kpi",      "ElementType": "VISUAL", "ColumnIndex": 24, "ColumnSpan": 12, "RowIndex": 0,  "RowSpan": 6},
                {"ElementId": "claims-by-type",     "ElementType": "VISUAL", "ColumnIndex": 0,  "ColumnSpan": 18, "RowIndex": 6,  "RowSpan": 12},
                {"ElementId": "claims-by-status",   "ElementType": "VISUAL", "ColumnIndex": 18, "ColumnSpan": 18, "RowIndex": 6,  "RowSpan": 12},
                {"ElementId": "claims-by-country",  "ElementType": "VISUAL", "ColumnIndex": 0,  "ColumnSpan": 18, "RowIndex": 18, "RowSpan": 12},
                {"ElementId": "top-claims-table",   "ElementType": "VISUAL", "ColumnIndex": 18, "ColumnSpan": 18, "RowIndex": 18, "RowSpan": 12}
              ],
              "CanvasSizeOptions": {
                "ScreenCanvasSizeOptions": {"ResizeOption": "FIXED", "OptimizedViewPortWidth": "1600px"}
              }
            }
          }
        }]
      },
      {
        "SheetId": "apj-risk-markets",
        "Name": "APJ Risk & Markets",
        "Visuals": [
          {
            "BarChartVisual": {
              "VisualId": "gdp-by-country",
              "Title": {"Visibility": "VISIBLE", "FormatText": {"PlainText": "GDP per Capita by Country"}},
              "ChartConfiguration": {
                "FieldWells": {
                  "BarChartAggregatedFieldWells": {
                    "Category": [{
                      "CategoricalDimensionField": {
                        "FieldId": "gdp-country-dim",
                        "Column": {"DataSetIdentifier": "apac_risk", "ColumnName": "COUNTRY"}
                      }
                    }],
                    "Values": [{
                      "NumericalMeasureField": {
                        "FieldId": "gdp-val",
                        "Column": {"DataSetIdentifier": "apac_risk", "ColumnName": "GDP_PER_CAPITA"},
                        "AggregationFunction": {"SimpleNumericalAggregation": "AVERAGE"}
                      }
                    }]
                  }
                },
                "Orientation": "HORIZONTAL",
                "BarsArrangement": "CLUSTERED"
              }
            }
          },
          {
            "BarChartVisual": {
              "VisualId": "insurance-pen-by-country",
              "Title": {"Visibility": "VISIBLE", "FormatText": {"PlainText": "Insurance Penetration by Country"}},
              "ChartConfiguration": {
                "FieldWells": {
                  "BarChartAggregatedFieldWells": {
                    "Category": [{
                      "CategoricalDimensionField": {
                        "FieldId": "ins-country-dim",
                        "Column": {"DataSetIdentifier": "apac_risk", "ColumnName": "COUNTRY"}
                      }
                    }],
                    "Values": [{
                      "NumericalMeasureField": {
                        "FieldId": "ins-pen-val",
                        "Column": {"DataSetIdentifier": "apac_risk", "ColumnName": "INSURANCE_PENETRATION"},
                        "AggregationFunction": {"SimpleNumericalAggregation": "AVERAGE"}
                      }
                    }]
                  }
                },
                "Orientation": "HORIZONTAL",
                "BarsArrangement": "CLUSTERED"
              }
            }
          },
          {
            "BarChartVisual": {
              "VisualId": "disaster-by-country",
              "Title": {"Visibility": "VISIBLE", "FormatText": {"PlainText": "Disaster Exposure by Country"}},
              "ChartConfiguration": {
                "FieldWells": {
                  "BarChartAggregatedFieldWells": {
                    "Category": [{
                      "CategoricalDimensionField": {
                        "FieldId": "dis-country-dim",
                        "Column": {"DataSetIdentifier": "apac_risk", "ColumnName": "COUNTRY"}
                      }
                    }],
                    "Values": [{
                      "NumericalMeasureField": {
                        "FieldId": "dis-exp-val",
                        "Column": {"DataSetIdentifier": "apac_risk", "ColumnName": "NATURAL_DISASTER_EXPOSURE"},
                        "AggregationFunction": {"SimpleNumericalAggregation": "AVERAGE"}
                      }
                    }]
                  }
                },
                "Orientation": "HORIZONTAL",
                "BarsArrangement": "CLUSTERED"
              }
            }
          },
          {
            "TableVisual": {
              "VisualId": "country-risk-table",
              "Title": {"Visibility": "VISIBLE", "FormatText": {"PlainText": "Country Risk Detail"}},
              "ChartConfiguration": {
                "FieldWells": {
                  "TableAggregatedFieldWells": {
                    "GroupBy": [
                      {"CategoricalDimensionField": {"FieldId": "risk-country", "Column": {"DataSetIdentifier": "apac_risk", "ColumnName": "COUNTRY"}}},
                      {"CategoricalDimensionField": {"FieldId": "risk-code", "Column": {"DataSetIdentifier": "apac_risk", "ColumnName": "COUNTRY_CODE"}}}
                    ],
                    "Values": [
                      {"NumericalMeasureField": {"FieldId": "risk-gdp", "Column": {"DataSetIdentifier": "apac_risk", "ColumnName": "GDP_PER_CAPITA"}, "AggregationFunction": {"SimpleNumericalAggregation": "AVERAGE"}}},
                      {"NumericalMeasureField": {"FieldId": "risk-ins", "Column": {"DataSetIdentifier": "apac_risk", "ColumnName": "INSURANCE_PENETRATION"}, "AggregationFunction": {"SimpleNumericalAggregation": "AVERAGE"}}},
                      {"NumericalMeasureField": {"FieldId": "risk-dis", "Column": {"DataSetIdentifier": "apac_risk", "ColumnName": "NATURAL_DISASTER_EXPOSURE"}, "AggregationFunction": {"SimpleNumericalAggregation": "AVERAGE"}}},
                      {"NumericalMeasureField": {"FieldId": "risk-pop", "Column": {"DataSetIdentifier": "apac_risk", "ColumnName": "POPULATION"}, "AggregationFunction": {"SimpleNumericalAggregation": "SUM"}}}
                    ]
                  }
                }
              }
            }
          }
        ],
        "Layouts": [{
          "Configuration": {
            "GridLayout": {
              "Elements": [
                {"ElementId": "gdp-by-country",          "ElementType": "VISUAL", "ColumnIndex": 0,  "ColumnSpan": 18, "RowIndex": 0,  "RowSpan": 12},
                {"ElementId": "insurance-pen-by-country", "ElementType": "VISUAL", "ColumnIndex": 18, "ColumnSpan": 18, "RowIndex": 0,  "RowSpan": 12},
                {"ElementId": "disaster-by-country",      "ElementType": "VISUAL", "ColumnIndex": 0,  "ColumnSpan": 18, "RowIndex": 12, "RowSpan": 12},
                {"ElementId": "country-risk-table",       "ElementType": "VISUAL", "ColumnIndex": 18, "ColumnSpan": 18, "RowIndex": 12, "RowSpan": 12}
              ],
              "CanvasSizeOptions": {
                "ScreenCanvasSizeOptions": {"ResizeOption": "FIXED", "OptimizedViewPortWidth": "1600px"}
              }
            }
          }
        }]
      }
    ],
    "AnalysisDefaults": {
      "DefaultNewSheetConfiguration": {
        "InteractiveLayoutConfiguration": {
          "Grid": {
            "CanvasSizeOptions": {
              "ScreenCanvasSizeOptions": {
                "ResizeOption": "FIXED",
                "OptimizedViewPortWidth": "1600px"
              }
            }
          }
        }
      }
    }
  }
}
EOJSON

echo "  Creating analysis from definition..."
aws quicksight create-analysis --cli-input-json "file://${ANALYSIS_DEF}" --region "$REGION" 2>&1 \
  && ok "Analysis: insurance-apj-analysis" || fail "Analysis creation"
rm -f "$ANALYSIS_DEF"

# ── Step 4: Publish dashboard ─────────────────────────────────────────────────
echo ""
echo "=== Step 4: Create dashboard ==="

ANALYSIS_ARN="arn:aws:quicksight:${REGION}:${ACCT}:analysis/insurance-apj-analysis"

echo "  Creating template from analysis..."
aws quicksight create-template \
  --aws-account-id "$ACCT" --region "$REGION" \
  --template-id "insurance-apj-template" \
  --name "APJ Insurance Claims Template" \
  --source-entity "{
    \"SourceAnalysis\": {
      \"Arn\": \"${ANALYSIS_ARN}\",
      \"DataSetReferences\": [
        {\"DataSetPlaceholder\": \"claims\", \"DataSetArn\": \"${CLAIMS_DS_ARN}\"},
        {\"DataSetPlaceholder\": \"apac_risk\", \"DataSetArn\": \"${RISK_DS_ARN}\"}
      ]
    }
  }" 2>&1

echo "  Waiting for template..."
sleep 10

TEMPLATE_ARN="arn:aws:quicksight:${REGION}:${ACCT}:template/insurance-apj-template"

echo "  Creating dashboard from template..."
aws quicksight create-dashboard \
  --aws-account-id "$ACCT" --region "$REGION" \
  --dashboard-id "insurance-apj-dashboard" \
  --name "APJ Insurance Claims Dashboard" \
  --source-entity "{
    \"SourceTemplate\": {
      \"Arn\": \"${TEMPLATE_ARN}\",
      \"DataSetReferences\": [
        {\"DataSetPlaceholder\": \"claims\", \"DataSetArn\": \"${CLAIMS_DS_ARN}\"},
        {\"DataSetPlaceholder\": \"apac_risk\", \"DataSetArn\": \"${RISK_DS_ARN}\"}
      ]
    }
  }" \
  --permissions "[{\"Principal\":\"${QS_USER_ARN}\",\"Actions\":[\"quicksight:DescribeDashboard\",\"quicksight:ListDashboardVersions\",\"quicksight:UpdateDashboardPermissions\",\"quicksight:QueryDashboard\",\"quicksight:UpdateDashboard\",\"quicksight:DeleteDashboard\",\"quicksight:DescribeDashboardPermissions\",\"quicksight:UpdateDashboardPublishedVersion\"]}]" \
  --dashboard-publish-options '{"AdHocFilteringOption":{"AvailabilityStatus":"ENABLED"},"ExportToCSVOption":{"AvailabilityStatus":"ENABLED"},"SheetControlsOption":{"VisibilityState":"EXPANDED"}}' \
  2>&1 && ok "Dashboard: insurance-apj-dashboard" || fail "Dashboard creation"

# ── Step 5: Create Q topic ────────────────────────────────────────────────────
echo ""
echo "=== Step 5: Create Q topic ==="

Q_TOPIC_DEF=$(mktemp)
cat > "$Q_TOPIC_DEF" <<EOJSON
{
  "AwsAccountId": "${ACCT}",
  "TopicId": "insurance-apj-q-topic",
  "Topic": {
    "Name": "APJ Insurance Claims",
    "Description": "Insurance claims data across 8 Asia-Pacific markets with AI evaluation status",
    "DataSets": [{
      "DatasetArn": "${CLAIMS_DS_ARN}",
      "DatasetName": "APJ Insurance Claims",
      "Columns": [
        {"ColumnName": "CLAIM_ID", "ColumnFriendlyName": "Claim ID", "ColumnDescription": "Unique claim identifier", "ColumnSynonyms": ["claim number","claim ref"], "IsIncludedInTopic": true, "SemanticType": {"TypeName": "ID"}},
        {"ColumnName": "CLAIM_TYPE", "ColumnFriendlyName": "Claim Type", "ColumnDescription": "Type of insurance claim", "ColumnSynonyms": ["type","category","claim category"], "IsIncludedInTopic": true},
        {"ColumnName": "POLICY_TYPE", "ColumnFriendlyName": "Policy Type", "ColumnDescription": "Insurance policy type", "ColumnSynonyms": ["policy","insurance type","product"], "IsIncludedInTopic": true},
        {"ColumnName": "STATUS", "ColumnFriendlyName": "Claim Status", "ColumnDescription": "Current status of the claim", "ColumnSynonyms": ["state","progress","stage"], "IsIncludedInTopic": true},
        {"ColumnName": "COUNTRY", "ColumnFriendlyName": "Country", "ColumnDescription": "APJ country where claim originated", "ColumnSynonyms": ["market","region","location","nation"], "IsIncludedInTopic": true},
        {"ColumnName": "CITY", "ColumnFriendlyName": "City", "ColumnDescription": "City where claim originated", "ColumnSynonyms": ["town","location"], "IsIncludedInTopic": true},
        {"ColumnName": "CLAIM_AMOUNT", "ColumnFriendlyName": "Claim Amount", "ColumnDescription": "Dollar amount claimed", "ColumnSynonyms": ["amount","value","cost","claim value","claim cost"], "IsIncludedInTopic": true, "Aggregation": "SUM"},
        {"ColumnName": "COVERAGE_LIMIT", "ColumnFriendlyName": "Coverage Limit", "ColumnDescription": "Maximum coverage for the policy", "ColumnSynonyms": ["coverage","limit","max coverage"], "IsIncludedInTopic": true, "Aggregation": "AVERAGE"},
        {"ColumnName": "DEDUCTIBLE", "ColumnFriendlyName": "Deductible", "ColumnDescription": "Policy deductible amount", "ColumnSynonyms": ["excess"], "IsIncludedInTopic": true, "Aggregation": "AVERAGE"},
        {"ColumnName": "PREMIUM", "ColumnFriendlyName": "Premium", "ColumnDescription": "Annual insurance premium", "ColumnSynonyms": ["price","annual premium"], "IsIncludedInTopic": true, "Aggregation": "SUM"},
        {"ColumnName": "AI_DECISION", "ColumnFriendlyName": "AI Decision", "ColumnDescription": "Bedrock AI evaluation result", "ColumnSynonyms": ["decision","ai result","evaluation","recommendation"], "IsIncludedInTopic": true},
        {"ColumnName": "FILING_DATE", "ColumnFriendlyName": "Filing Date", "ColumnDescription": "Date the claim was filed", "ColumnSynonyms": ["date","filed","submission date"], "IsIncludedInTopic": true},
        {"ColumnName": "FIRST_NAME", "ColumnFriendlyName": "First Name", "ColumnDescription": "Claimant first name", "IsIncludedInTopic": true},
        {"ColumnName": "LAST_NAME", "ColumnFriendlyName": "Last Name", "ColumnDescription": "Claimant last name", "IsIncludedInTopic": true},
        {"ColumnName": "POLICY_NUMBER", "ColumnFriendlyName": "Policy Number", "ColumnDescription": "Policy reference number", "IsIncludedInTopic": true},
        {"ColumnName": "COUNTRY_GDP_PER_CAPITA", "ColumnFriendlyName": "GDP per Capita", "ColumnDescription": "Country GDP per capita from World Bank", "ColumnSynonyms": ["gdp","income"], "IsIncludedInTopic": true, "Aggregation": "AVERAGE"},
        {"ColumnName": "COUNTRY_INSURANCE_PENETRATION", "ColumnFriendlyName": "Insurance Penetration", "ColumnDescription": "Insurance penetration rate", "ColumnSynonyms": ["penetration","insurance rate"], "IsIncludedInTopic": true, "Aggregation": "AVERAGE"},
        {"ColumnName": "COUNTRY_DISASTER_EXPOSURE", "ColumnFriendlyName": "Disaster Exposure", "ColumnDescription": "Natural disaster exposure rate", "ColumnSynonyms": ["disaster risk","exposure","catastrophe"], "IsIncludedInTopic": true, "Aggregation": "AVERAGE"},
        {"ColumnName": "AI_REASONING", "ColumnFriendlyName": "AI Reasoning", "ColumnDescription": "AI explanation for the decision", "IsIncludedInTopic": false}
      ]
    }]
  }
}
EOJSON

aws quicksight create-topic --cli-input-json "file://${Q_TOPIC_DEF}" --region "$REGION" 2>&1 \
  && ok "Q Topic: insurance-apj-q-topic" || fail "Q Topic creation"
rm -f "$Q_TOPIC_DEF"

# Grant Q topic permissions
aws quicksight update-topic-permissions \
  --aws-account-id "$ACCT" --region "$REGION" \
  --topic-id "insurance-apj-q-topic" \
  --grant-permissions "[{\"Principal\":\"${QS_USER_ARN}\",\"Actions\":[\"quicksight:DescribeTopic\",\"quicksight:DescribeTopicPermissions\",\"quicksight:DescribeTopicRefresh\",\"quicksight:ListTopicReviewedAnswers\",\"quicksight:CreateTopicReviewedAnswer\",\"quicksight:DeleteTopicReviewedAnswer\",\"quicksight:PassTopic\"]}]" \
  2>&1 && ok "Q Topic permissions granted" || echo "  Warning: Q topic permissions may need manual grant"

# ── Step 6: Final validation ──────────────────────────────────────────────────
echo ""
echo "=== Final QuickSight Validation ==="
echo ""

# Check datasets
echo "Datasets:"
for DS in insurance-claims-ds insurance-apac-country-risk insurance-extracted-notes; do
  S=$(aws quicksight describe-data-set --aws-account-id "$ACCT" --region "$REGION" \
    --data-set-id "$DS" --query 'DataSet.Name' --output text 2>/dev/null || echo "MISSING")
  echo "  $DS → $S"
done

# Check analysis
echo ""
echo "Analysis:"
A_STATUS=$(aws quicksight describe-analysis --aws-account-id "$ACCT" --region "$REGION" \
  --analysis-id "insurance-apj-analysis" --query 'Analysis.Status' --output text 2>/dev/null || echo "MISSING")
echo "  insurance-apj-analysis → $A_STATUS"

# Check dashboard
echo ""
echo "Dashboard:"
D_STATUS=$(aws quicksight describe-dashboard --aws-account-id "$ACCT" --region "$REGION" \
  --dashboard-id "insurance-apj-dashboard" --query 'Dashboard.Version.Status' --output text 2>/dev/null || echo "MISSING")
echo "  insurance-apj-dashboard → $D_STATUS"

# Check Q topic
echo ""
echo "Q Topic:"
T_NAME=$(aws quicksight describe-topic --aws-account-id "$ACCT" --region "$REGION" \
  --topic-id "insurance-apj-q-topic" --query 'Topic.Name' --output text 2>/dev/null || echo "MISSING")
echo "  insurance-apj-q-topic → $T_NAME"

echo ""
echo "Dashboard URL: https://${REGION}.quicksight.aws.amazon.com/sn/dashboards/insurance-apj-dashboard"
echo "Analysis URL:  https://${REGION}.quicksight.aws.amazon.com/sn/analyses/insurance-apj-analysis"
echo ""
echo "=== QuickSight deployment complete ==="

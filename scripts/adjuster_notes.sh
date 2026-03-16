#!/usr/bin/env bash
set -euo pipefail

BUCKET="sf-insurance-demo-apj-2026"
PREFIX="adjuster-notes"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "=== Generating 10 adjuster notes ==="

cat > "$TMPDIR/adjuster_note_001.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Number: CLM-001
Date of Inspection: 2025-09-20
Location: Tsim Sha Tsui, Kowloon, Hong Kong
Adjuster: David Wong (License #HK4521)

INCIDENT DETAILS:
Insured's 2024 Mercedes-Benz S580 was stolen from the basement parking garage of K11 MUSEA shopping mall on September 17, 2025, between 19:30-22:45. Security cameras confirm vehicle entry at 19:22 but show no exit footage of the vehicle. Theft discovered upon insured's return from dinner.

POLICE INVOLVEMENT:
- Case reported to Tsim Sha Tsui Police Station (Case #TST-2025-0917-284)
- CCTV footage obtained from mall security
- Vehicle details circulated to border control points

EVIDENCE COLLECTED:
- Mall parking ticket (entry time verified)
- Police report
- Security camera footage
- Vehicle registration documents
- Original keys in insured's possession
- GPS tracking system disabled at 21:03

COST BREAKDOWN:
2024 Mercedes-Benz S580 Base Value: $72,000.00
Custom Wheels and Tires: $2,800.00
Recently Installed Audio System: $721.80
Total Loss Amount: $75,521.80

FINDINGS:
Physical evidence and documentation support the theft claim. No signs of insurance fraud detected. Vehicle equipped with factory anti-theft system and GPS tracking. Professional theft likely involved, given location and execution. Recommend approval of claim minus deductible ($1,000).

RECOMMENDATION:
Approve claim payment of $74,521.80 (total loss minus deductible)

David Wong
Senior Claims Adjuster
Hong Kong Insurance Adjusters Ltd.
NOTEEOF

cat > "$TMPDIR/adjuster_note_002.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Number: CLM-002
Date of Inspection: January 18, 2026
Location: Causeway Bay, Hong Kong
Field Adjuster: Raymond Wong (License #HK4472)

INCIDENT DETAILS:
On January 16, 2026, at approximately 14:30 local time, insured's vehicle (2025 Mercedes-Benz S-Class) was involved in a collision with a commercial delivery van at the intersection of Hennessy Road and Canal Road East. CCTV footage from nearby buildings confirms insured had right of way when the delivery van failed to stop at the red light.

DAMAGE ASSESSMENT:
- Severe impact damage to front passenger side
- Structural damage to A-pillar and roof support
- Airbag deployment (front and side)
- Advanced driver assistance systems compromised
- High-voltage battery pack damaged (hybrid system)

COST BREAKDOWN:
1. Parts and Components: USD 89,765.32
   - Replacement body panels: USD 22,450
   - Battery pack: USD 42,315.32
   - ADAS components: USD 25,000

2. Labor and Installation: USD 45,729.35
   - Body work: USD 28,450
   - Electrical systems: USD 17,279.35

3. Third-party Property Damage: USD 36,000
   - Delivery van repairs: USD 31,000
   - Damaged cargo: USD 5,000

Total Claim Amount: USD 171,494.67
Less Deductible: USD 1,000
Net Claim: USD 170,494.67

SUPPORTING EVIDENCE:
- CCTV footage from three angles
- Police report #HK-2026-0116-243
- Photos of damage (47 images attached)
- Repair facility estimate from authorized Mercedes-Benz Service Center (Wan Chai)

RECOMMENDATION:
Based on inspection findings and documentation, recommend full approval of claim amount. Third-party liability is clearly established through video evidence and police report.
NOTEEOF

cat > "$TMPDIR/adjuster_note_003.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Number: CLM-003
Date of Inspection: 2025-09-24
Adjuster: David Chan (License #HK4472)
Location: 15F Tower B, Highland Park, Tai Po, New Territories, Hong Kong

INCIDENT DETAILS:
On September 21, 2025, Super Typhoon Meihua made landfall in Hong Kong with sustained winds of 195 km/h. The insured's 15th-floor apartment sustained significant damage from wind-driven rain and debris impact. Primary damage occurred when multiple windows failed due to pressure differential, allowing water intrusion throughout the 1,200 sq ft unit.

OBSERVED DAMAGES:
- Complete failure of three bedroom windows and sliding doors
- Extensive water damage to hardwood flooring throughout (85% affected)
- Ceiling water damage in living room and master bedroom
- Mold development on drywall (30% of walls affected)
- Kitchen cabinetry water damage
- Electrical system compromise in affected areas
- Personal property damage including furniture and electronics

COST BREAKDOWN:
Window replacement: $42,500
Flooring removal and replacement: $68,400
Drywall repair and painting: $35,800
Kitchen renovation: $45,900
Electrical system repairs: $18,500
Personal property replacement: $48,667.83
Mold remediation: $15,500
Temporary housing allowance: $2,500
Total: $277,767.83

EVIDENCE COLLECTED:
- 147 digital photographs
- Moisture meter readings from all affected areas
- Weather report from Hong Kong Observatory
- Contractor evaluation reports (3)
- Engineering assessment of structural integrity

RECOMMENDATION:
Based on documented evidence and policy coverage, recommend full approval of claim amount less deductible ($2,500). Damage is consistent with reported weather event and falls within policy limits.
NOTEEOF

cat > "$TMPDIR/adjuster_note_004.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Number: CLM-004
Date of Inspection: December 10, 2025
Adjuster: Michael Chan (License #HK2241)
Location: 15F Tower B, Highland Park, Tai Po, New Territories, Hong Kong

INCIDENT DETAILS:
On December 8, 2025, Typhoon Saola (Category 4) made landfall in Hong Kong, causing significant structural damage to Ms. Wong's 15th-floor apartment. Primary damage occurred between 02:00-04:00 when wind speeds exceeded 180 km/h.

OBSERVED DAMAGES:
1. Complete destruction of master bedroom window system (3.5m x 2m)
2. Water infiltration affecting 85% of wooden flooring (120 sq meters)
3. Structural damage to concrete balcony railing
4. Interior wall water damage in three rooms
5. HVAC system compromised by water intrusion
6. Personal property damage (furniture, electronics, artwork)

COST BREAKDOWN:
- Window replacement & installation: $28,500
- Flooring removal and replacement: $36,000
- Structural repairs (balcony): $22,450
- Wall repairs and repainting: $15,800
- HVAC system repairs: $12,500
- Personal property replacement: $24,841.57
- Temporary protective measures: $2,500
Total: $142,591.57

EVIDENCE COLLECTED:
- 47 digital photographs
- Weather report from Hong Kong Observatory
- Building management incident report
- Three contractor estimates
- Original purchase receipts for damaged items

RECOMMENDATION:
Based on policy coverage and documented evidence, I recommend full approval of claim amount minus deductible ($2,500). Total recommended payout: $140,091.57.

Additional Notes: Property requires immediate temporary weather protection. Recommend expedited processing due to ongoing rainy season.

Michael Chan
Senior Claims Adjuster
Hong Kong Property Claims Division
NOTEEOF

cat > "$TMPDIR/adjuster_note_005.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Number: CLM-005
Date of Report: 2025-11-23
Adjuster: Wong Mei-ling (#HK2241)
Location: Hong Kong Adventist Hospital - Stubbs Road, Happy Valley, Hong Kong

INCIDENT DETAILS:
On November 15, 2025, insured David Lam (age 42) was admitted to Hong Kong Adventist Hospital following severe abdominal pain diagnosed as acute appendicitis requiring immediate surgical intervention. Patient presented with fever and localized pain in lower right quadrant.

MEDICAL PROCEDURES:
- Emergency laparoscopic appendectomy
- Three-day post-operative hospital stay
- Follow-up care and antibiotics

EVIDENCE REVIEWED:
1. Hospital admission records
2. Surgical reports from Dr. Chen Wei-ming
3. Laboratory test results
4. Post-operative care documentation
5. Original medical bills and receipts
6. Pharmacy dispensing records

COST BREAKDOWN:
Surgical procedure: USD 22,450.00
Hospital stay (3 days): USD 12,600.00
Anesthesia: USD 3,875.00
Laboratory tests: USD 1,654.35
Post-operative medications: USD 945.00
Follow-up consultations: USD 1,400.00
Total claimed amount: USD 42,924.35

COVERAGE ANALYSIS:
Policy limit: USD 100,000
Deductible: USD 3,000
Net payable amount: USD 39,924.35

RECOMMENDATIONS:
Based on review of all medical documentation and current policy terms, I recommend full approval of claim less deductible. All procedures were medically necessary and costs align with standard rates for private hospitals in Hong Kong. No evidence of pre-existing condition or policy exclusions noted.

Wong Mei-ling
Senior Claims Adjuster
Hong Kong Region
NOTEEOF

cat > "$TMPDIR/adjuster_note_006.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Number: CLM-006
Date of Report: 2025-10-15
Adjuster: Wong Mei-ling (#HK2241)
Location: Hong Kong Adventist Hospital - Stubbs Road

INCIDENT DETAILS:
On October 8, 2025, insured David Lam (age 42) was admitted to Hong Kong Adventist Hospital following severe abdominal pain and fever. Emergency diagnostic tests revealed acute appendicitis with complications. Patient underwent emergency laparoscopic appendectomy on October 9, 2025, followed by five days of inpatient care due to post-surgical infection.

EVIDENCE REVIEWED:
- Hospital admission records
- Surgical reports from Dr. Chen Wei-ming
- Laboratory test results
- Medical imaging (CT scan) reports
- Detailed hospital billing statements
- Prescription medication records

COST BREAKDOWN:
1. Initial Emergency Room Visit: HKD 12,450
2. Diagnostic Tests & Imaging: HKD 28,760
3. Surgical Procedure: HKD 168,900
4. Hospital Room (5 days): HKD 45,500
5. Post-surgical Medications: HKD 15,890
6. Follow-up Consultations: HKD 8,500
Total: HKD 680,000 (USD 86,560.35)

FINDINGS:
All medical procedures were deemed necessary and appropriate for the condition. Costs align with standard private hospital rates in Hong Kong. Documentation is complete and verified. No pre-existing conditions noted. Claim falls within policy coverage limits.

RECOMMENDATION:
Based on thorough review of medical documentation and current policy terms, recommend full approval of claim amount USD 86,560.35, less deductible of USD 3,000.00. Net payment recommended: USD 83,560.35.

Wong Mei-ling
Senior Claims Adjuster
Hong Kong Region
NOTEEOF

cat > "$TMPDIR/adjuster_note_007.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Number: CLM-007
Date of Inspection: 2026-02-15
Adjuster: Wong Mei Ling (#SG-ADJ-2241)
Location: Mount Elizabeth Novena Hospital, Singapore

INCIDENT DETAILS:
Ms. Linda Tan (age 42) was diagnosed with Stage 3 breast cancer following routine mammogram screening at Mount Elizabeth Novena Hospital on 2026-01-28. Initial biopsy confirmed invasive ductal carcinoma in left breast with lymph node involvement.

EVIDENCE REVIEWED:
- Medical records from Dr. Chen Wei Ming (Oncologist)
- Pathology report dated 2026-01-30
- PET-CT scan results showing metastasis to axillary lymph nodes
- Treatment plan documentation
- Hospital admission records
- Original policy documentation (#LP-98765432)

COST BREAKDOWN:
1. Initial diagnostics and biopsy: USD 12,458.30
2. PET-CT scan and imaging: USD 8,924.50
3. Surgical procedure (mastectomy): USD 68,750.00
4. Hospital stay (8 days): USD 42,300.00
5. Chemotherapy (first 3 cycles): USD 156,800.00
6. Radiation therapy (planned): USD 95,600.00
7. Medications and supplies: USD 13,749.98

Total claimed amount: USD 398,582.78
Deductible applicable: USD 250.00
Net payable amount: USD 398,332.78

FINDINGS:
Claim is valid under policy terms. All medical procedures are deemed necessary and costs are within acceptable range for Singapore private healthcare. Documentation is complete and verified. Treatment plan follows standard protocols for Stage 3 breast cancer. Recommend approval of claim amount after deductible.

Additional Notes:
Patient is currently undergoing chemotherapy with good response. Prognosis is favorable with current treatment plan. Follow-up assessment may be required for subsequent treatment phases.
NOTEEOF

cat > "$TMPDIR/adjuster_note_008.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Number: CLM-008
Date of Inspection: 2026-01-24
Adjuster: Wong Mei Ling (#SG2241)
Location: Mount Elizabeth Hospital, Singapore

INCIDENT DETAILS:
Ms. Linda Tan (age 42) was diagnosed with Stage 2 breast cancer following routine mammogram screening at Mount Elizabeth Hospital on 2026-01-15. Initial biopsy confirmed invasive ductal carcinoma in the left breast.

MEDICAL EVIDENCE REVIEWED:
- Diagnostic mammogram and ultrasound reports dated 2026-01-15
- Biopsy results (Ref: ME-26-0119) confirming malignancy
- Oncologist consultation notes from Dr. Chen Wei Ming
- Proposed treatment plan documentation
- Hospital admission records

TREATMENT PLAN COSTS:
1. Initial diagnostics and biopsy: SGD 12,450
2. Surgical procedure (lumpectomy): SGD 38,900
3. Post-operative care: SGD 8,775
4. Chemotherapy (6 cycles): SGD 89,600
5. Radiation therapy (planned): SGD 24,800
Total: SGD 174,525 (USD 130,977.52)

FINDINGS:
Claim is valid under policy terms. Medical documentation supports diagnosis and necessity of treatment. All procedures fall within usual and customary rates for Singapore private healthcare facilities. Patient has completed surgical intervention and commenced chemotherapy on 2026-01-20.

RECOMMENDATION:
Approve claim amount of USD 130,977.52 less deductible of USD 250.00. Total recommended payout: USD 130,727.52

Additional Notes:
Follow-up assessment recommended after completion of chemotherapy cycle. Prognosis is favorable with 85% five-year survival rate according to treating oncologist.

Wong Mei Ling
Senior Claims Adjuster
Singapore Branch Office
NOTEEOF

cat > "$TMPDIR/adjuster_note_009.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Number: CLM-009
Date of Inspection: November 5, 2025
Adjuster: Marcus Tan (License #SG2245)
Location: 78 Shenton Way, Singapore 079120

INCIDENT OVERVIEW:
On October 31, 2025, at approximately 14:30, a water pipe burst on the 12th floor of the insured's commercial property, causing significant water damage to three floors below. The affected area includes tenant spaces occupied by two law firms and a financial consulting company.

DAMAGE ASSESSMENT:
- Water penetration through ceiling and walls affecting approximately 450 square meters
- Damaged office equipment including 12 workstations
- Compromised electrical systems requiring partial rewiring
- Extensive damage to carpeting and wall coverings
- Mold risk identified in drywall sections

COST BREAKDOWN:
1. Water damage restoration: SGD 45,000
2. Electrical system repairs: SGD 28,500
3. Office equipment replacement: SGD 32,000
4. Carpet and wall covering replacement: SGD 22,000
5. Temporary relocation costs: SGD 10,000
Total: SGD 137,500 (USD 102,254.50)

EVIDENCE COLLECTED:
- Photographic documentation of all affected areas
- Building maintenance records showing recent pipe inspection
- Security camera footage confirming time of incident
- Tenant statements and damage claims
- Professional assessment from licensed plumber (Report #PL-2025/445)

RECOMMENDATIONS:
Claim appears valid and within policy coverage. Recommend full approval less deductible. Preventive measures suggested for remaining pipeline infrastructure to prevent future incidents.

NEXT STEPS:
1. Process claim payment
2. Issue preventive maintenance advisory
3. Schedule follow-up inspection after repairs

Marcus Tan
Senior Claims Adjuster
Singapore Insurance Adjusters Pte Ltd
NOTEEOF

cat > "$TMPDIR/adjuster_note_010.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Date of Inspection: January 8, 2026
Claim Number: CLM-010
Adjuster: Marcus Tan (License #SG2024-789)
Location: 123 Tanjong Pagar Road, Singapore 088456

INCIDENT DETAILS:
On January 3, 2026, at approximately 22:30 hours, a severe thunderstorm caused significant water damage to the insured's commercial property. Heavy rainfall, combined with blocked drainage systems, resulted in flooding on the ground floor retail space. Water ingress affected approximately 1,200 square feet of retail space, including inventory storage areas.

OBSERVED DAMAGES:
- Water damage to drywall and baseboards (ground floor)
- Damaged wooden flooring and subflooring
- Affected electrical outlets and wiring below 2 feet
- Inventory damage: clothing merchandise and storage boxes
- Mold growth detected on walls (readings: 85% relative humidity)

EVIDENCE COLLECTED:
- 47 digital photographs
- Security camera footage showing water ingress
- Weather report from NEA confirming rainfall of 102mm
- Moisture meter readings from affected areas
- Original purchase receipts for damaged inventory

COST BREAKDOWN:
1. Water extraction and drying: $8,750
2. Drywall replacement: $6,880
3. Electrical repairs: $4,200
4. Flooring replacement: $12,300
5. Inventory losses: $7,500
6. Mold remediation: $1,500.17

Total Claimed Amount: $41,130.17
Less Deductible: $5,000
Net Claim Amount: $36,130.17

RECOMMENDATIONS:
Claim is valid under policy terms. Recommend full approval of net claim amount. Suggest preventive measures including drainage system upgrade to prevent future incidents.

Marcus Tan
Senior Claims Adjuster
Singapore Claims Management Ltd.
NOTEEOF

echo "=== Uploading to s3://$BUCKET/$PREFIX/ ==="
for f in "$TMPDIR"/adjuster_note_*.txt; do
    fname=$(basename "$f")
    aws s3 cp "$f" "s3://$BUCKET/$PREFIX/$fname" --quiet
    echo "  uploaded $fname"
done

echo "=== Verifying uploads ==="
count=$(aws s3 ls "s3://$BUCKET/$PREFIX/" | wc -l | tr -d ' ')
echo "  $count files in s3://$BUCKET/$PREFIX/"

if [ "$count" -eq 10 ]; then
    echo "=== SUCCESS: All 10 adjuster notes uploaded ==="
else
    echo "=== WARNING: Expected 10 files, found $count ==="
    exit 1
fi

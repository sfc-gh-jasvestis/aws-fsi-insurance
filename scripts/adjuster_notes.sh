#!/usr/bin/env bash
set -euo pipefail

# Generates 10 adjuster note text files and uploads them to S3.
# Run during Phase 3 (Step 3.4) — requires the S3 bucket to already exist.

BUCKET="sf-insurance-demo-apj"
PREFIX="adjuster-notes"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "=== Generating 10 adjuster notes ==="

cat > "$TMPDIR/adjuster_note_001.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Reference: CLM-001
Date of Inspection: 15 January 2024
Adjuster: Lim Wei Ming
Location: Singapore (Block 123, Toa Payoh North, #12-345, Singapore 310123)

Property Details:
4-room HDB apartment, approximately 990 sq ft
Built: 1995
Current Occupancy: Owner-occupied

Damage Assessment:
Extensive water damage observed affecting the master bedroom, adjacent bathroom, and common corridor. The incident originated from a burst pipe concealed within the common bathroom wall. Water has saturated approximately 215 sq ft of flooring, with visible damage to the parquet flooring which shows significant warping and buckling. Moisture meter readings indicate elevated levels (28-35%) in affected wall sections up to 1.2 meters height. Bathroom wall tiles show signs of delamination, with approximately 40% of tiles requiring replacement. Paint bubbling and peeling observed on three walls. The built-in wardrobe in the master bedroom has sustained water damage at its base, with visible swelling of the particle board material. No structural damage to concrete walls or ceiling observed. Mold growth noted in corner sections of affected areas, particularly where the bathroom wall meets the bedroom wall. Water stains visible on corridor walls extending approximately 3 meters from point of origin.

Estimated Repair Cost: USD 12,800
- Flooring replacement: $5,200
- Wall repairs and painting: $2,800
- Bathroom retiling: $2,400
- Built-in wardrobe replacement: $1,900
- Plumbing repairs: $500

Claimant Cooperation: Excellent
- Provided immediate access to property
- All requested documentation submitted promptly
- Maintained clear communication throughout

Recommendation: APPROVE
Damage clearly results from sudden pipe burst, which is a covered peril under policy terms. Damage extent and repair costs are reasonable for the type of incident. No evidence of pre-existing conditions or maintenance neglect that would void coverage. Recommend full approval of claim amount with standard deductible applied.
NOTEEOF

cat > "$TMPDIR/adjuster_note_002.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Reference: CLM-002
Date of Inspection: 15 November 2023
Adjuster: Lim Wei Ming
Location: Singapore
Property Details: Commercial Office Unit #12-05, Marina Bay Financial Centre Tower 3

Damage Assessment:
Extensive water damage observed affecting approximately 85 square meters of office space following the failure of a concealed water pipe in the ceiling void. The affected areas include suspended ceiling tiles (40% requiring replacement), carpeted flooring throughout, and gypsum board walls particularly in the northeast corner. Moisture meter readings indicate significant water saturation in walls up to 1.2m height. Three workstations show severe water damage to wooden surfaces and electrical components. Document storage cabinets and their contents sustained water damage. Mold growth visible on lower sections of affected walls, indicating the incident occurred approximately 72 hours before reporting. The primary source of water ingress has been identified as a corroded copper pipe joint above ceiling tile grid reference C7. Secondary damage noted to network cabling infrastructure and electrical trunking. No structural damage observed to concrete elements. Emergency mitigation measures including dehumidification already in progress by approved contractor.

Estimated Repair Cost: USD 42,500

Claimant Cooperation: Excellent - provided immediate access and all requested documentation

Recommendation: APPROVE
Reasoning: Damage consistent with reported incident. Policy coverage confirmed. Quantum reasonable for scope of repairs required. No evidence of pre-existing conditions or maintenance neglect. Recommend processing claim with standard deductible application.
NOTEEOF

cat > "$TMPDIR/adjuster_note_003.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Reference: CLM-003
Date: 15 March 2024
Adjuster: Tanaka Hiroshi
Location: Tokyo, Japan
Property Type: Commercial Office Space - 12th Floor, Shibuya Cross Tower

Damage Assessment:
Extensive water damage observed affecting approximately 180 square meters of office space following the failure of a main water supply pipe in the ceiling void. The burst pipe occurred during weekend hours, resulting in prolonged water exposure. Primary damage includes: waterlogged suspended ceiling tiles (80% requiring replacement), severe water staining and delamination of gypsum wall boards along the northern and eastern walls, warping of engineered wood flooring throughout, and water infiltration into electrical conduits. Three workstation clusters show damage to electronic equipment including monitors and desktop computers. Moisture meter readings indicate elevated levels (28-35%) in wall cavities, suggesting potential hidden damage. Mold growth already visible in several corners, particularly near HVAC vents. Building maintenance records indicate the pipe system was last inspected 4 years ago, exceeding recommended inspection intervals.

Estimated Repair Cost: USD 78,500
- Ceiling replacement: $12,000
- Wall repairs and painting: $15,500
- Flooring replacement: $22,000
- Electrical system inspection/repair: $8,000
- Equipment replacement: $16,000
- Mold remediation: $5,000

Claimant Cooperation: Excellent - Provided immediate access, all requested documentation, and maintenance records promptly.

Recommendation: APPROVE
Damage clearly results from sudden and accidental pipe failure. No evidence of maintenance negligence that would void coverage. Repair costs are reasonable for scope of damage. Recommend expedited processing to prevent secondary damage from moisture exposure.
NOTEEOF

cat > "$TMPDIR/adjuster_note_004.txt" << 'NOTEEOF'
Field Inspection Report
Claim Reference: CLM-004
Date: 15 March 2024
Adjuster: Tanaka Hiroshi
Location: Japan (Yokohama City, Kanagawa Prefecture)

Property Details:
Commercial building - 4-story office complex
Address: 2-1-5 Minato Mirai, Nishi-ku, Yokohama
Construction: Steel frame with glass curtain wall
Year Built: 2015

Damage Assessment:
Extensive water damage observed on floors 2 and 3 following the rupture of a main water supply line in the ceiling void of the 3rd floor. The burst pipe occurred during non-business hours, resulting in approximately 8 hours of continuous water flow before discovery. Affected areas include: suspended ceiling systems (approximately 400 sq meters), electrical conduits, IT infrastructure, carpeting, and drywall partitions. Visible mold growth already present in several wall cavities. Water has penetrated through multiple layers of drywall and insulation. Desktop computers, workstations, and office furniture on both floors have sustained significant water damage. Building's electrical system shows signs of water ingress in junction boxes and conduits. Professional moisture readings indicate elevated levels in structural elements requiring immediate drying intervention to prevent secondary damage.

Estimated Repair Cost: USD 285,000
- Water damage restoration: $95,000
- Electrical system repairs: $45,000
- Interior finishes replacement: $75,000
- Equipment/furniture replacement: $70,000

Claimant Cooperation: Excellent
Property manager provided immediate access, all requested documentation, and maintenance records promptly.

Recommendation: APPROVE
Cause of loss clearly accidental and covered under policy terms. No evidence of maintenance negligence. Immediate remediation necessary to prevent further damage and business interruption. Recommend expedited claim processing to minimize business impact.
NOTEEOF

cat > "$TMPDIR/adjuster_note_005.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Reference: CLM-005
Date: 15 November 2023
Adjuster: Somchai Thongchai
Location: Bangkok, Thailand
Property Type: Commercial Building - 4-story retail complex
Address: 789 Sukhumvit Road, Watthana, Bangkok 10110

DAMAGE ASSESSMENT:
Extensive water damage observed across multiple floors resulting from blocked drainage system during recent heavy monsoon rains. Primary affected areas include the ground floor retail spaces and basement parking facility. Water ingress through compromised roof membrane has caused significant ceiling damage on 4th floor. Visible signs of water staining on walls, warped wooden flooring in ground floor retail units, and compromised electrical systems. Mold growth detected in approximately 40% of affected areas. Building's main electrical room shows signs of water exposure, requiring immediate attention. HVAC system impacted with water damage to ducting and air handling units. Several shop tenants reported inventory losses, though these fall outside building coverage scope. Structural assessment reveals no immediate stability concerns, but prolonged exposure to moisture may compromise internal wall integrity if not addressed promptly. Emergency mitigation measures already implemented include temporary roof repairs and water extraction from basement levels.

Estimated Repair Cost: USD 285,000

Claimant Cooperation: High - Property management provided full access and documentation

Recommendation: APPROVE
Damages clearly fall within policy coverage for water damage from blocked drainage systems. No evidence of pre-existing maintenance issues or negligence. Recommend immediate approval to prevent further deterioration and secondary damage. Suggest phased repair approach prioritizing electrical systems and roof membrane replacement.
NOTEEOF

cat > "$TMPDIR/adjuster_note_006.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Reference: CLM-006
Date: 15 November 2023
Adjuster: Somchai Thongchai
Location: Bangkok, Thailand
Property: Commercial Building - Sukhumvit Plaza, 12-story office complex
Age of Building: 18 years

DAMAGE ASSESSMENT:
Extensive water damage observed across floors 8-12 resulting from tropical storm overflow of rooftop drainage system. Primary affected areas include suspended ceilings, electrical conduits, and wall cavities. Moisture meter readings indicate severe saturation of gypsum board walls (readings 95-100% in multiple locations). Visible mold growth present in approximately 40% of affected areas, particularly in corner offices and server room on 10th floor. HVAC system shows signs of water infiltration with standing water in air handling units. Carpeting throughout affected floors is completely saturated and requires replacement. Several workstations and office furniture items show irreversible water damage. Building's main electrical distribution panel on 9th floor exhibits corrosion from water exposure, requiring immediate attention. Structural assessment reveals no compromise to building integrity, though decorative ceiling elements show risk of collapse in several areas. Emergency water extraction was performed by building management, but significant residual moisture remains.

Estimated Repair Cost: USD 875,000

Claimant Cooperation: Excellent - provided immediate access and all requested documentation

Recommendation: APPROVE
Reasoning: Damage clearly results from covered peril (storm water ingress). All damage documented is consistent with reported cause of loss. Building maintenance records show regular upkeep of drainage system; no evidence of contributory negligence. Repair costs are in line with scope of damage and local market rates.
NOTEEOF

cat > "$TMPDIR/adjuster_note_007.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Reference: CLM-007
Date: 15 March 2024
Adjuster: Somchai Thongchai
Location: Bangkok, Thailand
Property Type: Commercial Restaurant (2-story shophouse)
Address: 789 Sukhumvit Soi 55, Watthana, Bangkok 10110

DAMAGE ASSESSMENT:
Extensive water damage observed following roof failure during severe monsoon storm on 10 March 2024. Primary affected areas include main dining room ceiling (85 sq m), kitchen area (45 sq m), and second-floor storage space (60 sq m). Ceiling plasterboard shows significant water saturation with multiple collapse points. Black mold development evident in corner sections, particularly near HVAC vents. Electrical systems compromised with visible corrosion on main distribution board. Kitchen equipment affected includes hood ventilation system and lighting fixtures. Water penetration has caused warping of hardwood flooring in dining area, requiring full replacement. Wall paint bubbling and peeling throughout affected areas. Supporting wooden structures in roof space show signs of prolonged water exposure with potential structural compromise. Secondary damage to POS systems and dining furniture noted. Emergency temporary repairs (tarpaulin covering) in place but inadequate for long-term resolution.

Estimated Repair Cost: USD 78,500
- Roof replacement: $25,000
- Interior repairs: $32,000
- Equipment replacement: $15,000
- Electrical system repairs: $6,500

Claimant Cooperation: Excellent - provided all requested documentation promptly, including previous maintenance records and contractor quotes.

RECOMMENDATION: APPROVE
Damage clearly falls within policy coverage for storm damage. No evidence of pre-existing conditions or maintenance negligence. All damage consistent with reported storm event and supported by weather records. Recommend full approval of claim with standard depreciation applications per policy terms.
NOTEEOF

cat > "$TMPDIR/adjuster_note_008.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Reference: CLM-008
Date: 15 March 2024
Adjuster: Somchai Thongchai
Location: Bangkok, Thailand
Property Type: Commercial Building - 4-story retail complex

DAMAGE ASSESSMENT:
Extensive water damage observed across multiple floors following severe monsoon flooding. Primary affected areas include ground floor retail spaces and basement parking facility. Ground floor shows clear water line at 1.2m height with significant damage to drywall, electrical systems, and floor coverings. Mold growth already visible on walls up to 1.5m height. Six retail units severely impacted with destroyed inventory and fixtures. Basement parking area remains partially flooded (0.3m depth) with evidence of structural damage to support columns - concrete spalling observed in three locations. Electrical distribution panel completely submerged during peak flooding requiring full replacement. HVAC system damaged beyond repair due to water infiltration. External drainage system showed signs of pre-existing maintenance issues which likely contributed to water ingress severity. Building's waterproofing system appears to have failed at multiple points, particularly around service penetrations and expansion joints.

Estimated Repair Cost: USD 875,000

Claimant Cooperation: High - provided all requested documentation and facilitated multiple site visits

Recommendation: REFER
Reasoning: While damage is consistent with reported flood event, pre-existing maintenance issues with drainage system may affect coverage. Structural concerns in basement require engineering assessment before final settlement determination. Recommend engaging structural engineer for detailed evaluation of column damage.
NOTEEOF

cat > "$TMPDIR/adjuster_note_009.txt" << 'NOTEEOF'
FIELD INSPECTION REPORT
Claim Reference: CLM-009
Date: 15 November 2023
Adjuster: Somchai Thongchai
Location: Bangkok, Thailand
Property Type: Commercial Building - 4-story retail complex

DAMAGE ASSESSMENT:
Extensive water damage observed across multiple floors following severe monsoon flooding. Primary affected areas include ground floor retail spaces and basement parking facility. Ground floor shows clear water line at 1.2m height with significant damage to drywall, electrical systems, and floor coverings. Mold growth already visible on walls and wooden fixtures. Six retail units severely impacted with destroyed inventory and fixtures. Basement parking level completely flooded with standing water still present at 0.3m depth at time of inspection. Electrical distribution panels submerged during peak flooding requiring full replacement. HVAC system components in basement severely damaged. Structural assessment reveals no immediate concerns to building foundation, however water penetration through expansion joints requires remediation. External drainage system blocked with debris contributing to water ingress. Emergency response measures including water extraction and dehumidification already initiated by property management. Temporary power systems installed for basic lighting and security systems.

Estimated Repair Cost: USD 875,000

Claimant Cooperation: Excellent - provided all requested documentation and facilitated immediate access

RECOMMENDATION: APPROVE
Damage consistent with reported flood event and policy coverage. All damage properly documented and mitigation efforts promptly implemented. Recommend full approval of claim with standard depreciation applications per policy terms.
NOTEEOF

cat > "$TMPDIR/adjuster_note_010.txt" << 'NOTEEOF'
Field Inspection Report
Claim Reference: CLM-010
Date: 15 March 2024
Adjuster: Somchai Wattana
Location: Bangkok, Thailand
Property Type: Commercial Building - 4-story retail complex

Damage Assessment:
Conducted thorough inspection of water damage resulting from severe roof leak during recent monsoon rains. Primary affected areas span the entire top floor (4th) and significant portions of the 3rd floor. Evidence of prolonged water infiltration observed through deteriorated ceiling panels, compromised electrical systems, and extensive mold growth along western wall sections. Approximately 680 square meters of retail space impacted. Specific damages include:
- Collapsed suspended ceiling systems in 40% of 4th floor area
- Severe water staining and warping of drywall in 12 separate locations
- Complete failure of electrical systems in northwest quadrant
- Mold contamination requiring remediation in approximately 220 square meters
- Damaged merchandise inventory in 4 retail units
- Compromised HVAC ductwork showing rust and contamination
- Structural assessment reveals no compromise to building integrity
Secondary damage noted to ground floor retail units from water migration through service ducts.

Estimated Repair Cost: $285,000 USD

Claimant Cooperation: High - Property manager provided immediate access, complete documentation, and maintenance records

Recommendation: APPROVE
Damages clearly result from covered peril (storm damage to roof) with no evidence of pre-existing conditions or maintenance negligence. All damage properly documented and costs reasonable for scope of repairs needed. Recommend full approval with standard deductible application.
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

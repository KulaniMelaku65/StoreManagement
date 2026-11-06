# Store Keeper — Role, Responsibilities & System Access

Based on the Inventory/Store functionality already built into the ERP (native Business Central Item/Location/Fixed Asset engine + Fanisi_Finance's Custom GRN, Store Requisition/Issue, and Asset Transfer modules).

> Note: no "Store Keeper" permission set exists yet in the Fanisi apps — this document defines what should be configured, as a starting point for your BC administrator to build the actual Permission Set(s) in Business Central.

---

## 1. Who this applies to

| Role | Level |
|---|---|
| **Store Keeper** | Operational — receives, stores, and issues stock day to day |
| **Store Keeper Manager / Store Supervisor** | Supervisory — approves requisitions/transfers, reviews stock accuracy, escalates budget or shortage issues |

---

## 2. Store Keeper — Responsibilities

| Responsibility | ERP Document/Object |
|---|---|
| Receive goods against a purchase order/LPO | **Custom GRN** (Header + Lines) |
| Check what's physically in the store vs. system | Item Card → "Qty in Store" / Inventory flowfield, filtered by their Location |
| Issue stock against an approved staff request | **Store Requisition → Store Issue** |
| Warn/stop issuing when stock is insufficient | System auto-checks "Qty in Store" live off Item Ledger Entries when a requisition line is entered |
| Hand over or receive a Fixed/Minor Asset | **Asset Transfer** (as the person executing a transfer already approved) |
| Flag discrepancies at physical count | Physical Inventory Journal (standard BC) — counted vs. system qty |
| Keep item descriptions/units consistent | View-only on Item Card; report errors rather than edit master data |

## 3. Store Keeper Manager — Additional Responsibilities

| Responsibility | ERP Document/Object |
|---|---|
| Approve/reject Store Requisitions | Store Requisition Status: Open → Pending Approval → Approved/Posted |
| Approve Asset Transfers | Asset Transfer Status: Open → Pending Approval → Approved |
| Monitor budget exposure on requisitions | Budget Account / Budget Center fields on requisition lines |
| Review stock valuation / aging / low stock | Item Availability by Location, Inventory Valuation, custom Aged reports |
| Authorize adjustments after a physical count | Physical Inventory Journal posting |
| Escalate purchasing needs | Purchase Requisition → GRN follow-up (Qty Ordered vs. Qty Received) |

---

## 4. Recommended System Access

### Store Keeper — should have

**Full/Edit access:**
- Custom GRN (create, edit lines, post receipt)
- Store Requisition Lines — enter/adjust Quantity To Issue on **approved** requisitions
- Store Issue (post the issue that reduces stock)
- Asset Transfer Lines — execute a transfer already marked Approved (record actual handover date/time)
- Physical Inventory Journal — entry of counted quantities (not posting/adjustment approval)

**View-only access:**
- Item Card / Item List (their assigned Location only, if location-based security is used)
- Item Ledger Entries (their location) — to explain stock movements
- Fixed Asset List/Card for assets currently at their location
- Purchase Order / LPO — to confirm what's expected before it arrives

**No access:**
- Item Card cost fields, G/L Budget Account, posting groups
- Approving their own Store Requisitions or Asset Transfers (segregation of duties)
- General Ledger, Vendor Ledger, Bank/Cash modules
- Fixed Asset depreciation posting, disposal, or FA Depreciation Book setup
- User/permission administration

### Store Keeper Manager — should additionally have

**Full/Edit access:**
- Approve/reject Store Requisitions and Asset Transfers
- Post Physical Inventory adjustments
- View and act on Budget Account balances tied to store issues
- Fixed Asset List — assign/reassign FA Location Code, mark "Minor Asset" status

**View-only access:**
- Inventory Valuation, Item Availability by Location, GRN vs. PO follow-up reports
- Depreciation/Book Value reports (Assets Summary report) — read-only, not posting

**No access:**
- Posting depreciation runs or disposing assets (should sit with Finance/Fixed Assets owner)
- General Ledger posting, Vendor payments

---

## 5. Segregation of duties to enforce

- The person who **requests** an item/asset should not be the same person who **approves** or **issues** it.
- The **Store Keeper** posts GRNs and Store Issues, but should not be the one who **approves** Store Requisitions or Asset Transfers — that's the Manager's job.
- **Fixed Asset depreciation and disposal** stay with Finance, not the store team — the store team's involvement in Fixed Assets should stop at physical custody (Asset Transfer) and location tagging, not financial posting.
- Physical count **entry** (Store Keeper) should be separate from count **approval/adjustment posting** (Manager), so stock can't be silently corrected by the person responsible for it.

---

## 6. Practical setup notes for your BC administrator

1. Create two Permission Sets: `STOREKEEPER` and `STOREKEEPER-MGR` (or extend `STOREKEEPER` with an additional set for the manager, since BC permission sets stack).
2. If multiple physical stores exist, apply **Location-based security filtering** so a Store Keeper only sees/posts against their own Location — otherwise anyone with the Store Keeper permission set can post GRNs/Issues at any store.
3. Consider a lightweight **Role Center** (page) for the Store Keeper, similar to the existing `ProcurementManagement` and `GeneralRequisitions` role centers already in Fanisi_Finance, so their landing page shows only Store Requisitions awaiting issue, GRNs to process, and Asset Transfers to execute — rather than the full Business Manager menu.

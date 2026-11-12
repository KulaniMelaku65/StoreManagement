query 60181 "Store Employee Assets API"
{
    // Items and assets issued to employees: the Employee Items custody ledger
    // (Fanisi_HR), with the employee and - for tagged units - the matching
    // Asset Register row (serial number, model, class, where it sits).
    //
    // Portal usage:
    //   One employee's items:          .../employeeAssets?$filter=employeeNo eq 'KFT0001'
    //   Only what they still hold:     ...and returned eq false
    //   Who holds a given unit:        .../employeeAssets?$filter=tagNo eq 'KFT-IT-LAP-0040'
    //
    // The Asset Register is joined on Tag No., not Item No.: when a unit has a
    // Fixed Asset card, Item No. holds the Fixed Asset No., so it is not a
    // reliable key into the register. Both joins are left outer joins, so
    // consumables (no tag) still come back, just with the asset columns blank.
    Caption = 'Employee Assets';
    QueryType = API;
    APIPublisher = 'Kifiya';
    APIGroup = 'KifiyaGroup';
    APIVersion = 'v1.0';
    EntityName = 'employeeAsset';
    EntitySetName = 'employeeAssets';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(employeeItem; "Employee Items")
        {
            column(employeeNo; "Employee No.")
            {
                Caption = 'Employee No.';
            }
            column(lineNo; "Line No.")
            {
                Caption = 'Line No.';
            }
            column(itemType; "Item Type")
            {
                Caption = 'Item Type';
            }
            column(itemNo; "Item No.")
            {
                Caption = 'Item No.';
            }
            column(description; Description)
            {
                Caption = 'Description';
            }
            column(tagNo; "Tag No.")
            {
                Caption = 'Tag No.';
            }
            column(quantity; Quantity)
            {
                Caption = 'Quantity';
            }
            column(sourceDocNo; "Source Doc. No.")
            {
                // Requisition or transfer number; OPENING for assets employees
                // already held at go-live.
                Caption = 'Source Document No.';
            }
            column(issuingStore; "Issuing Store")
            {
                Caption = 'Issued From';
            }
            column(approvedBy; "Approved By")
            {
                Caption = 'Approved By';
            }
            column(startDate; "Start Date")
            {
                Caption = 'Start Date';
            }
            column(endDate; "End Date")
            {
                Caption = 'End Date';
            }
            column(allocated; Allocated)
            {
                Caption = 'Allocated';
            }
            column(dateAllocated; "Date Allocated")
            {
                Caption = 'Date Allocated';
            }
            column(allocatedBy; "Allocated By")
            {
                Caption = 'Allocated By';
            }
            column(returned; Returned)
            {
                Caption = 'Returned';
            }
            column(dateReturned; "Date Returned")
            {
                Caption = 'Date Returned';
            }
            column(returnCapturedBy; "Return Captured By")
            {
                Caption = 'Return Captured By';
            }
            dataitem(employee; Employee)
            {
                DataItemLink = "No." = employeeItem."Employee No.";
                SqlJoinType = LeftOuterJoin;

                column(employeeFullName; "Full Name")
                {
                    Caption = 'Employee Full Name';
                }
                column(jobTitle; "Job Title")
                {
                    Caption = 'Job Title';
                }
                column(department; "Global Dimension 2 Code")
                {
                    Caption = 'Department';
                }
                dataitem(assetRegister; "Store Asset Register")
                {
                    DataItemLink = "Tag No." = employeeItem."Tag No.";
                    SqlJoinType = LeftOuterJoin;

                    column(assetClass; Category)
                    {
                        Caption = 'Asset Class';
                    }
                    column(assetType; "Type")
                    {
                        Caption = 'Asset Type';
                    }
                    column(model; Model)
                    {
                        Caption = 'Model';
                    }
                    column(serialNo; "Serial No.")
                    {
                        Caption = 'Serial No.';
                    }
                    column(fixedAssetNo; "Fixed Asset No.")
                    {
                        Caption = 'Fixed Asset No.';
                    }
                    column(assetCondition; Status)
                    {
                        Caption = 'Condition';
                    }
                    column(availability; "Availability Status")
                    {
                        Caption = 'Availability';
                    }
                    column(locationCode; "Location Code")
                    {
                        Caption = 'Location';
                    }
                }
            }
        }
    }
}

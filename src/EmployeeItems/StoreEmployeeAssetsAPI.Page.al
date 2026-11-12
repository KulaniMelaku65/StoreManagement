page 60182 "Store Employee Assets API"
{
    // One JSON object per employee, with everything issued to them nested
    // under "assets" (see the "Store Employee Asset Lines API" sub-page).
    //
    // Portal usage - the assets array only comes back when asked for with
    // $expand (standard OData behaviour):
    //   Everyone holding something:  .../employeeAssets?$filter=holdingCount gt 0&$expand=assets
    //   One employee:                .../employeeAssets('KFT0144')?$expand=assets
    //   Only what they still hold:   ...?$expand=assets($filter=status eq 'in_use')
    PageType = API;
    Caption = 'Employee Assets';
    APIPublisher = 'Kifiya';
    APIGroup = 'KifiyaGroup';
    APIVersion = 'v1.0';
    EntityName = 'employeeAsset';
    EntitySetName = 'employeeAssets';
    SourceTable = Employee;
    ODataKeyFields = "No.";
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DataAccessIntent = ReadOnly;

    layout
    {
        area(content)
        {
            repeater(Employees)
            {
                field(employeeNo; Rec."No.")
                {
                    Caption = 'Employee No.';
                }
                field(employeeName; Rec."Full Name")
                {
                    Caption = 'Employee Name';
                }
                field(department; Rec."Global Dimension 2 Code")
                {
                    Caption = 'Department';
                }
                field(holdingCount; Rec."Store Items Held")
                {
                    Caption = 'Holding Count';
                }
                field(totalCount; Rec."Store Items Total")
                {
                    Caption = 'Total Count';
                }
                part(assets; "Store Employee Asset Lines API")
                {
                    Caption = 'Assets';
                    EntityName = 'asset';
                    EntitySetName = 'assets';
                    SubPageLink = "Employee No." = field("No.");
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Store Items Held", "Store Items Total");
    end;
}

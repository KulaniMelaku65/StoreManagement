page 60175 "Store Asset Lookup"
{
    PageType = List;
    SourceTable = "Store Asset Register";
    Caption = 'Select Asset';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    // The short pick-list used wherever someone chooses a tagged unit (store
    // requisition line, asset transfer): the tag and what it is, first.

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Tag No."; Rec."Tag No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Model; Rec.Model)
                {
                    ApplicationArea = All;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = All;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field("Availability Status"; Rec."Availability Status")
                {
                    ApplicationArea = All;
                }
                field("Assigned To"; Rec."Assigned To")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

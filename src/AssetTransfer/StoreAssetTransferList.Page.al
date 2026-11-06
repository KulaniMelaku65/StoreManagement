page 60171 "Store Asset Transfer List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Store Asset Transfer";
    CardPageId = "Store Asset Transfer Card";
    Caption = 'Asset Transfers';
    Editable = false;
    DeleteAllowed = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                }
                field("Tag No."; Rec."Tag No.")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("From Holder"; Rec."From Holder")
                {
                    ApplicationArea = All;
                }
                field("To Employee Name"; Rec."To Employee Name")
                {
                    ApplicationArea = All;
                }
                field("From Location Code"; Rec."From Location Code")
                {
                    ApplicationArea = All;
                }
                field("To Location Code"; Rec."To Location Code")
                {
                    ApplicationArea = All;
                }
                field(Reason; Rec.Reason)
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                }
                field("Confirmed By"; Rec."Confirmed By")
                {
                    ApplicationArea = All;
                }
                field("Transferred Date"; Rec."Transferred Date")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}

pageextension 60153 "Custom GRN Lines Page Ext" extends "Custom GRN Lines"
{
    layout
    {
        addafter("Unit Of Measure")
        {
            field("Location Code"; Rec."Location Code")
            {
                ApplicationArea = All;
                ToolTip = 'Location from the purchase order line. Flows onto the Asset or Inventory Register when the GRN is confirmed.';
            }
        }
        addafter("Unit Cost")
        {
            field("Unit Cost Incl. VAT"; Rec."Unit Cost Incl. VAT")
            {
                ApplicationArea = All;
                ToolTip = 'Unit cost plus VAT, from the purchase line this GRN line came from. Same as Unit Cost when there is no VAT.';
            }
        }
        addafter("Line Amount")
        {
            field("Line Amount Incl. VAT"; Rec."Line Amount Incl. VAT")
            {
                ApplicationArea = All;
            }
        }
        addafter("Item No")
        {
            field(Category; Rec.Category)
            {
                ApplicationArea = All;
                ToolTip = 'Asset Class for this unit - fill this in (with Type, Model, Serial No. if known) before confirming the GRN, so it flows straight onto the Asset Register, tagged automatically.';
            }
            field("Asset Type"; Rec."Asset Type")
            {
                ApplicationArea = All;
                ToolTip = 'Type for this unit, if used - folds into the generated Tag Number.';
            }
            field(Model; Rec.Model)
            {
                ApplicationArea = All;
            }
            field("Serial No."; Rec."Serial No.")
            {
                ApplicationArea = All;
            }
        }
    }
}

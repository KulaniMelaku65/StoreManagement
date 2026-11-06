pageextension 60122 "Posted Purchase Invoice Ext" extends "Posted Purchase Invoice"
{
    layout
    {
        addafter("Vendor Invoice No.")
        {
            field("GRN Generated"; Rec."GRN Generated")
            {
                ApplicationArea = All;
            }
            field("GRN No."; Rec."GRN No.")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        addafter(Print)
        {
            action("Create GRN")
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                Image = Segment;
                Enabled = not Rec."GRN Generated";
                ToolTip = 'Generate a goods received note for this posted invoice.';

                trigger OnAction()
                begin
                    PostedInvoiceGRNMgt.GenerateGRNFromPostedInvoice(Rec);
                end;
            }
        }
    }

    var
        PostedInvoiceGRNMgt: Codeunit "Posted Invoice GRN Mgt.";
}

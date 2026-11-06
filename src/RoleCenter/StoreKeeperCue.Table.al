table 60107 "Store Keeper Cue"
{
    Caption = 'Store Keeper Cue';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Open Store Requisitions"; Integer)
        {
            Caption = 'Open Store Requisitions';
            FieldClass = FlowField;
            CalcFormula = count("PROC-Store Requistion Header" where(Status = const(Open)));
            Editable = false;
        }
        field(3; "Requisitions Ready to Issue"; Integer)
        {
            Caption = 'Requisitions Ready to Issue';
            FieldClass = FlowField;
            CalcFormula = count("PROC-Store Requistion Header" where(Status = const(Released)));
            Editable = false;
        }
        field(4; "Pending Goods Receipts"; Integer)
        {
            Caption = 'Pending Goods Receipts';
            FieldClass = FlowField;
            CalcFormula = count("Custom GRN Header" where(Status = const(Pending)));
            Editable = false;
        }
        field(5; "Open Asset Transfers"; Integer)
        {
            Caption = 'Open Asset Transfers';
            FieldClass = FlowField;
            CalcFormula = count("Store Asset Transfer" where(Status = const(Open)));
            Editable = false;
        }
        field(6; "Asset Transfers Ready"; Integer)
        {
            Caption = 'Asset Transfers Ready to Execute';
            FieldClass = FlowField;
            CalcFormula = count("Store Asset Transfer" where(Status = const(Confirmed)));
            Editable = false;
        }
        field(7; "Approved Purchase Orders"; Integer)
        {
            Caption = 'Approved Purchase Orders';
            FieldClass = FlowField;
            CalcFormula = count("Purchase Header" where("Document Type" = const(Order), Status = const(Released)));
            Editable = false;
        }
        field(8; "Purchase Invoices Ready"; Integer)
        {
            Caption = 'Purchase Invoices Ready';
            FieldClass = FlowField;
            // Create GRN now runs from the Posted Purchase Invoice, not the unposted
            // one - count posted invoices still waiting on a GRN, matching where the
            // drill-down actually sends you.
            CalcFormula = count("Purch. Inv. Header" where("GRN Generated" = const(false)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}

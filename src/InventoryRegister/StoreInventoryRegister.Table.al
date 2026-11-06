table 60149 "Store Inventory Register"
{
    Caption = 'Inventory Register';
    DataClassification = CustomerContent;
    LookupPageId = "Store Inventory Register List";
    DrillDownPageId = "Store Inventory Register List";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            Editable = false;
        }
        field(10; Category; Code[10])
        {
            Caption = 'Category';
            TableRelation = "Store Inventory Category";
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(30; "Location Code"; Code[10])
        {
            Caption = 'Location';
            TableRelation = Location;
        }
        field(40; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measurement';
            TableRelation = "Unit of Measure";
        }
        field(50; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(60; "Unit Cost"; Decimal)
        {
            Caption = 'Unit Cost';
            MinValue = 0;
        }
        field(61; "Total Cost"; Decimal)
        {
            Caption = 'Total Cost';
            Editable = false;
        }
        field(70; "Physical Count"; Decimal)
        {
            Caption = 'Physical Count';
            DecimalPlaces = 0 : 5;
        }
        field(80; Variance; Decimal)
        {
            Caption = 'Variance';
            Editable = false;
            DecimalPlaces = 0 : 5;
        }
        field(90; "Program Code"; Code[20])
        {
            Caption = 'Program';
        }
        field(100; Status; Enum "Store Asset Condition")
        {
            Caption = 'Status';
        }
        field(110; Remarks; Text[250])
        {
            Caption = 'Remarks';
        }
        field(120; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
            Editable = false;
        }
        field(130; "Last Counted Date"; Date)
        {
            Caption = 'Last Counted Date';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Cat; Category, "Location Code")
        {
        }
    }

    trigger OnInsert()
    begin
        UpdateCalculatedFields();
    end;

    trigger OnModify()
    begin
        UpdateCalculatedFields();
    end;

    local procedure UpdateCalculatedFields()
    begin
        "Total Cost" := Round("Physical Count" * "Unit Cost", 0.01);
        Variance := "Physical Count" - Quantity;
    end;
}

table 60163 "Store Inv. Register Summary"
{
    Caption = 'Inventory Register Summary';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(10; Category; Code[10])
        {
            Caption = 'Category';
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(30; "Location Code"; Code[10])
        {
            Caption = 'Location';
        }
        field(40; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measurement';
        }
        field(50; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(60; "Total Quantity"; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(70; "Total Physical Count"; Decimal)
        {
            Caption = 'Physical Count';
            DecimalPlaces = 0 : 5;
        }
        field(80; "Total Variance"; Decimal)
        {
            Caption = 'Variance';
            DecimalPlaces = 0 : 5;
        }
        field(90; "Average Unit Cost"; Decimal)
        {
            Caption = 'Average Unit Cost';
        }
        field(100; "Total Cost"; Decimal)
        {
            Caption = 'Total Cost';
        }
        field(110; "No. of Register Rows"; Integer)
        {
            Caption = 'No. of Register Rows';
        }
        field(120; "Last Counted Date"; Date)
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
    }
}

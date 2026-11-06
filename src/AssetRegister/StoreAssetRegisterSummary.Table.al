table 60140 "Store Asset Register Summary"
{
    Caption = 'Asset Register Summary';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(10; Category; Code[10])
        {
            Caption = 'Asset Class';
        }
        field(15; "Type"; Code[10])
        {
            Caption = 'Type';
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(30; "Location Code"; Code[10])
        {
            Caption = 'Warehouse/Location';
        }
        field(50; Model; Text[100])
        {
            Caption = 'Model';
        }
        field(80; "Total Physical Count"; Decimal)
        {
            Caption = 'Total Physical Count';
            DecimalPlaces = 0 : 5;
        }
        field(81; "No. of Tagged Units"; Integer)
        {
            Caption = 'No. of Tagged Units';
        }
        field(82; "Available Units"; Integer)
        {
            Caption = 'Available Units';
        }
        field(83; "Issued Units"; Integer)
        {
            Caption = 'Issued Units';
        }
        field(84; "Disposed Units"; Integer)
        {
            Caption = 'Disposed Units';
        }
        field(100; "Total Cost"; Decimal)
        {
            Caption = 'Total Cost';
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

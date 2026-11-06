table 60133 "Store Asset Type"
{
    Caption = 'Asset Type';
    DataClassification = CustomerContent;
    LookupPageId = "Store Asset Types";
    DrillDownPageId = "Store Asset Types";

    fields
    {
        field(1; Code; Code[10])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}

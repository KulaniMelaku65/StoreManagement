table 60128 "Store Asset Category"
{
    Caption = 'Asset Category';
    DataClassification = CustomerContent;
    LookupPageId = "Store Asset Categories";
    DrillDownPageId = "Store Asset Categories";

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

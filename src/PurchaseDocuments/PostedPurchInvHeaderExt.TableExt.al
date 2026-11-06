tableextension 60121 "Posted Purch Inv Header Ext" extends "Purch. Inv. Header"
{
    fields
    {
        field(60100; "GRN Generated"; Boolean)
        {
            Caption = 'GRN Generated';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(60101; "GRN No."; Code[20])
        {
            Caption = 'GRN No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Custom GRN Header";
        }
    }
}

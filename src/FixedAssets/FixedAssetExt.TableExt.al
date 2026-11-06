tableextension 60110 "Store Ops Fixed Asset Ext" extends "Fixed Asset"
{
    fields
    {
        field(60100; "Tag No."; Code[30])
        {
            Caption = 'Tag No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                FixedAsset: Record "Fixed Asset";
            begin
                if "Tag No." = '' then
                    exit;
                FixedAsset.SetRange("Tag No.", "Tag No.");
                FixedAsset.SetFilter("No.", '<>%1', "No.");
                if not FixedAsset.IsEmpty() then
                    Error(TagInUseErr, "Tag No.", FixedAsset."No.");
            end;
        }
    }

    var
        TagInUseErr: Label 'Tag No. %1 is already assigned to fixed asset %2.', Comment = '%1 = tag number, %2 = fixed asset number';
}

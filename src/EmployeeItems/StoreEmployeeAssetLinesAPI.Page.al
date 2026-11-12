page 60183 "Store Employee Asset Lines API"
{
    // The "assets" array inside each employee of the Employee Assets API: one
    // entry per Employee Items row, with the Asset Register details of the
    // tagged unit. Not meant to be called on its own.
    PageType = API;
    Caption = 'Employee Asset Lines';
    APIPublisher = 'Kifiya';
    APIGroup = 'KifiyaGroup';
    APIVersion = 'v1.0';
    EntityName = 'asset';
    EntitySetName = 'assets';
    SourceTable = "Employee Items";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    DataAccessIntent = ReadOnly;
    Permissions = tabledata "Store Asset Register" = R;

    layout
    {
        area(content)
        {
            repeater(Lines)
            {
                field(systemId; Rec.SystemId)
                {
                    Caption = 'System Id';
                }
                field(id; LineId)
                {
                    // "<Line No.>-<Tag No.>", e.g. 20000-KFT-IT-LAP-0051.
                    Caption = 'Id';
                }
                field(itemNo; ItemNo)
                {
                    // The tag for an asset, otherwise the Item No. (consumables).
                    Caption = 'Item No.';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(issuedOn; Rec."Start Date")
                {
                    Caption = 'Issued On';
                }
                field(returnedOn; ReturnedOn)
                {
                    Caption = 'Returned On';
                }
                field(status; Status)
                {
                    // in_use, returned, or pending (recorded but not yet allocated).
                    Caption = 'Status';
                }
                field(assetClass; AssetRegister.Category)
                {
                    Caption = 'Asset Class';
                }
                field(assetType; AssetRegister."Type")
                {
                    Caption = 'Asset Type';
                }
                field(model; AssetRegister.Model)
                {
                    Caption = 'Model';
                }
                field(serialNo; AssetRegister."Serial No.")
                {
                    Caption = 'Serial No.';
                }
                field(condition; Condition)
                {
                    Caption = 'Condition';
                }
                field(location; AssetRegister."Location Code")
                {
                    Caption = 'Location';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Clear(AssetRegister);
        Condition := '';
        if Rec."Tag No." <> '' then begin
            AssetRegister.SetRange("Tag No.", Rec."Tag No.");
            if AssetRegister.FindFirst() then
                Condition := Format(AssetRegister.Status);
            ItemNo := Rec."Tag No.";
        end else
            ItemNo := Rec."Item No.";

        LineId := StrSubstNo(LineIdTxt, Rec."Line No.", ItemNo);

        case true of
            Rec.Returned:
                Status := 'returned';
            Rec.Allocated:
                Status := 'in_use';
            else
                Status := 'pending';
        end;

        // An API page cannot send null for a date; 0D would go out as
        // 0001-01-01. A text field that is empty until the item comes back
        // is easier for the portal to test.
        ReturnedOn := '';
        if Rec.Returned then
            // Fanisi stores Date Returned as a DateTime; the portal wants the date.
            if Rec."Date Returned" <> 0DT then
                ReturnedOn := Format(DT2Date(Rec."Date Returned"), 0, 9)
            else
                if Rec."End Date" <> 0D then
                    ReturnedOn := Format(Rec."End Date", 0, 9);
    end;

    var
        AssetRegister: Record "Store Asset Register";
        LineId: Text;
        ItemNo: Text;
        Status: Text;
        Condition: Text;
        ReturnedOn: Text;
        LineIdTxt: Label '%1-%2', Locked = true;
}

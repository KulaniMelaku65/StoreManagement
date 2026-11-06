codeunit 60145 "Store Asset Return Mgt."
{
    Permissions = tabledata "Store Asset Register" = RM;

    procedure MarkTagReturned(TagNo: Code[30])
    var
        AssetRegister: Record "Store Asset Register";
    begin
        if TagNo = '' then
            exit;
        AssetRegister.SetRange("Tag No.", TagNo);
        if not AssetRegister.FindFirst() then
            exit;
        if AssetRegister."Availability Status" <> AssetRegister."Availability Status"::Issued then
            exit;
        AssetRegister."Availability Status" := AssetRegister."Availability Status"::Available;
        AssetRegister."Return Date" := Today();
        AssetRegister."Return To" := CopyStr(UserId(), 1, MaxStrLen(AssetRegister."Return To"));
        AssetRegister."Assigned To" := '';
        AssetRegister.Modify(true);
    end;
}

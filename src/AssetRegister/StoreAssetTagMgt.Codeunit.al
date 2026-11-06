codeunit 60138 "Store Asset Tag Mgt."
{
    // Builds tags in the required KFT-<Class>-<Type>-<Serial> format, e.g.
    // KFT-IT-LAP-0001. The running number is the highest existing suffix for
    // that exact Class+Type prefix (checked against both this table and Fixed
    // Asset, same as the manual uniqueness check on Tag No. itself) plus one.
    Permissions = tabledata "Store Asset Register" = R, tabledata "Fixed Asset" = R;

    procedure GenerateTagNo(var AssetRegister: Record "Store Asset Register")
    var
        Prefix: Text[30];
        NewTag: Code[30];
    begin
        AssetRegister.TestField(Category);
        Prefix := PrefixFor(AssetRegister.Category, AssetRegister."Type");
        NewTag := BuildTagNo(Prefix, NextSequenceFor(Prefix));
        AssetRegister.Validate("Tag No.", CopyStr(NewTag, 1, MaxStrLen(AssetRegister."Tag No.")));
    end;

    // Splitting a bulk row into many individually tagged units needs one tag per
    // unit, but doing a fresh database lookup for every single one (as a plain
    // Insert() would, via TryAutoGenerateTagNo on OnInsert) doesn't scale - a row
    // with Physical Count 65 means 64 new rows, each triggering its own lookup,
    // which is exactly what was timing out. StartSequenceFor + BuildTagNo let a
    // caller look up the starting number ONCE, then build the rest of the tags
    // by simple string formatting with no further database access.
    procedure PrefixFor(Category: Code[10]; TypeCode: Code[10]): Text[30]
    begin
        if TypeCode <> '' then
            exit('KFT-' + Category + '-' + TypeCode + '-');
        exit('KFT-' + Category + '-');
    end;

    procedure StartSequenceFor(Category: Code[10]; TypeCode: Code[10]): Integer
    begin
        exit(NextSequenceFor(PrefixFor(Category, TypeCode)));
    end;

    procedure BuildTagNo(Prefix: Text[30]; Seq: Integer): Code[30]
    begin
        exit(CopyStr(Prefix + PadSeq(Seq), 1, 30));
    end;

    procedure TryAutoGenerateTagNo(var AssetRegister: Record "Store Asset Register")
    begin
        // Called from the table's OnInsert trigger - silently does nothing if
        // there isn't enough information yet (no Category), a tag was already
        // supplied (e.g. a real tag came in from the CSV/paste import), or this
        // is a bulk row (Physical Count <> 1, e.g. freshly created from a GRN
        // or CSV import covering several units) - a tag is only ever generated
        // for a row that represents exactly one physical unit. Bulk rows get
        // tagged unit-by-unit via Split into Tagged Units instead.
        if (AssetRegister."Tag No." = '') and (AssetRegister.Category <> '') and (AssetRegister."Physical Count" = 1) then
            GenerateTagNo(AssetRegister);
    end;

    procedure TryAutoGenerateTagNoOnEntry(var AssetRegister: Record "Store Asset Register")
    begin
        // Called from Category/Type's OnValidate while manually typing a row on
        // the Asset Register page - generates the tag the moment Asset Class (and
        // Type, if used) are entered, rather than waiting for the row to be saved
        // or requiring a separate Generate Tag No. click. No Physical Count check
        // here, unlike TryAutoGenerateTagNo above: a manually-entered row is
        // assumed to be one physical unit unless the store keeper later changes
        // Physical Count themselves (Split into Tagged Units handles that case
        // fine regardless, since the original row keeps whatever tag it already
        // has when split into units).
        if (AssetRegister."Tag No." = '') and (AssetRegister.Category <> '') then
            GenerateTagNo(AssetRegister);
    end;

    local procedure NextSequenceFor(Prefix: Text[30]): Integer
    var
        AssetRegister: Record "Store Asset Register";
        FixedAsset: Record "Fixed Asset";
        MaxSeq: Integer;
        ThisSeq: Integer;
        SuffixText: Text;
    begin
        // Look up only the single highest existing tag for this prefix instead of
        // scanning and parsing every matching row - with a couple hundred tags
        // already generated for a busy prefix (e.g. KFT-IT-OTH-*), rescanning all
        // of them on every single call added up to real, timeout-risking cost in
        // a bulk action processing many rows in one go.
        AssetRegister.SetCurrentKey("Tag No.");
        AssetRegister.SetAscending("Tag No.", false);
        AssetRegister.SetFilter("Tag No.", StrSubstNo('%1*', Prefix));
        if AssetRegister.FindFirst() then begin
            SuffixText := DelStr(AssetRegister."Tag No.", 1, StrLen(Prefix));
            if Evaluate(ThisSeq, SuffixText) and (ThisSeq > MaxSeq) then
                MaxSeq := ThisSeq;
        end;

        FixedAsset.SetCurrentKey("Tag No.");
        FixedAsset.SetAscending("Tag No.", false);
        FixedAsset.SetFilter("Tag No.", StrSubstNo('%1*', Prefix));
        if FixedAsset.FindFirst() then begin
            SuffixText := DelStr(FixedAsset."Tag No.", 1, StrLen(Prefix));
            if Evaluate(ThisSeq, SuffixText) and (ThisSeq > MaxSeq) then
                MaxSeq := ThisSeq;
        end;

        exit(MaxSeq + 1);
    end;

    local procedure PadSeq(Seq: Integer): Text[10]
    var
        SeqText: Text;
    begin
        SeqText := Format(Seq);
        while StrLen(SeqText) < 4 do
            SeqText := '0' + SeqText;
        exit(SeqText);
    end;
}

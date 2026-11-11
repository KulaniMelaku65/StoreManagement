page 60126 "Store Asset Register List"
{
    ApplicationArea = All;
    Caption = 'Asset Register';
    PageType = List;
    SourceTable = "Store Asset Register";
    UsageCategory = Lists;
    Editable = true;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Category; Rec.Category)
                {
                    ApplicationArea = All;
                }
                field("Type"; Rec."Type")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = All;
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = All;
                }
                field("Tag No."; Rec."Tag No.")
                {
                    ApplicationArea = All;
                }
                field(Model; Rec.Model)
                {
                    ApplicationArea = All;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = All;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                }
                field("Physical Count"; Rec."Physical Count")
                {
                    ApplicationArea = All;
                }
                field("Program Code"; Rec."Program Code")
                {
                    ApplicationArea = All;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = All;
                }
                field("Total Cost"; Rec."Total Cost")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
                field(Remarks; Rec.Remarks)
                {
                    ApplicationArea = All;
                }
                field("Fixed Asset No."; Rec."Fixed Asset No.")
                {
                    ApplicationArea = All;
                }
                field("Availability Status"; Rec."Availability Status")
                {
                    ApplicationArea = All;
                }
                field("Last Counted Date"; Rec."Last Counted Date")
                {
                    ApplicationArea = All;
                }
                field("PO No."; Rec."PO No.")
                {
                    ApplicationArea = All;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Procured Date"; Rec."Procured Date")
                {
                    ApplicationArea = All;
                }
                field("Issued Date"; Rec."Issued Date")
                {
                    ApplicationArea = All;
                }
                field("Assigned To"; Rec."Assigned To")
                {
                    ApplicationArea = All;
                }
                field("Return Date"; Rec."Return Date")
                {
                    ApplicationArea = All;
                }
                field("Return To"; Rec."Return To")
                {
                    ApplicationArea = All;
                }
                field("Reassigned Date"; Rec."Reassigned Date")
                {
                    ApplicationArea = All;
                }
                field("Reassigned To"; Rec."Reassigned To")
                {
                    ApplicationArea = All;
                }
                field("Disposal Method"; Rec."Disposal Method")
                {
                    ApplicationArea = All;
                }
                field("Disposal Status"; Rec."Disposal Status")
                {
                    ApplicationArea = All;
                }
                field("Disposal Requested Date"; Rec."Disposal Requested Date")
                {
                    ApplicationArea = All;
                }
                field("Disposal Date"; Rec."Disposal Date")
                {
                    ApplicationArea = All;
                }
                field("Disposal Approved By"; Rec."Disposal Approved By")
                {
                    ApplicationArea = All;
                }
                field("Disposal Approval Date"; Rec."Disposal Approval Date")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportCsv)
            {
                ApplicationArea = All;
                Caption = 'Import from CSV';
                Image = ImportExcel;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Bulk-load rows from a CSV file, in the order: Category, Description, Location, Zone, Shelf No., Tag No., Model, Serial No., UoM, Physical Count, Program, Unit Cost, Status, Remarks.';

                trigger OnAction()
                var
                    AssetImport: Codeunit "Store Asset Register Import";
                begin
                    AssetImport.ImportFromCsv();
                    CurrPage.Update(false);
                end;
            }
            action(LinkAssignedToEmployees)
            {
                ApplicationArea = All;
                Caption = 'Link Assigned To Employees';
                Image = LinkAccount;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'For assets employees already held before go-live: matches each Assigned To name to an Employee card and records the asset as issued to that employee, so it can later be returned or transferred. Rows that cannot be matched are left for you to correct, and the list is filtered to show them.';

                trigger OnAction()
                var
                    StoreAssetCustodyLinkMgt: Codeunit "Store Asset Custody Link Mgt.";
                    UnmatchedCount: Integer;
                begin
                    StoreAssetCustodyLinkMgt.LinkAssignedAssets(UnmatchedCount);
                    if UnmatchedCount > 0 then begin
                        Rec.SetRange("Availability Status", Rec."Availability Status"::Available);
                        Rec.SetFilter("Assigned To", '<>%1', '');
                    end;
                    CurrPage.Update(false);
                end;
            }
            action(ReviewNameMatches)
            {
                ApplicationArea = All;
                Caption = 'Review Name Matches';
                Image = MapAccounts;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'For Assigned To names that did not match an employee exactly (spelling mistakes, missing names, titles): see the closest employee for each, correct or accept it, and link the accepted ones.';
                RunObject = page "Store Assignee Matching";
            }
            action(MarkCounted)
            {
                ApplicationArea = All;
                Caption = 'Mark Counted Today';
                Image = CheckList;
                ToolTip = 'Stamp the selected entries as counted today, for a physical count exercise.';

                trigger OnAction()
                var
                    AssetRegister: Record "Store Asset Register";
                begin
                    CurrPage.SetSelectionFilter(AssetRegister);
                    if AssetRegister.FindSet(true) then
                        repeat
                            AssetRegister."Last Counted Date" := Today();
                            AssetRegister.Modify();
                        until AssetRegister.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
            // No "Create Fixed Asset Card" action here - Finance owns creating Fixed
            // Asset cards. A register row gets its Fixed Asset No. only from the GRN
            // flow (Store Asset Register GRN Mgt.), which links back to whatever
            // Finance already created - the store keeper never creates a new one.
            action(SplitIntoUnits)
            {
                ApplicationArea = All;
                Caption = 'Split into Tagged Units';
                Image = Split;
                ToolTip = 'Split a row that covers more than one physical unit (e.g. Physical Count = 12) into one row per unit, each with its own Tag Number, so units can be tracked and issued individually. The total count is unchanged - just spread across more rows. Rows with a fractional count (bulk consumables) are skipped.';

                trigger OnAction()
                var
                    AssetRegister: Record "Store Asset Register";
                    SelectedKeys: Record "Store Asset Register" temporary;
                    UnitsCreated: Integer;
                    RowsSkipped: Integer;
                begin
                    // Same reasoning as Generate Tag No.: SplitRow inserts new rows, which
                    // trigger auto tag generation (OnInsert), which scans this same table -
                    // that must not happen while a selection cursor is still open on it.
                    CurrPage.SetSelectionFilter(AssetRegister);
                    if AssetRegister.FindSet() then
                        repeat
                            SelectedKeys := AssetRegister;
                            SelectedKeys.Insert();
                        until AssetRegister.Next() = 0;

                    if SelectedKeys.FindSet() then
                        repeat
                            AssetRegister.Get(SelectedKeys."Entry No.");
                            if AssetRegister."Physical Count" > 1 then
                                UnitsCreated += SplitRow(AssetRegister)
                            else
                                RowsSkipped += 1;
                        until SelectedKeys.Next() = 0;

                    CurrPage.Update(false);
                    Message(SplitResultMsg, UnitsCreated, RowsSkipped);
                end;
            }
            action(GenerateTagNo)
            {
                ApplicationArea = All;
                Caption = 'Generate Tag No.';
                Image = BarCode;
                ToolTip = 'Backfill KFT-<Class>[-<Type>]-<Serial> tag numbers for the selected entry (or entries) that don''t have one yet. New entries get this automatically on save - use this for existing rows imported before that, or ones missing an Asset Class at the time.';

                trigger OnAction()
                var
                    AssetRegister: Record "Store Asset Register";
                    SelectedKeys: Record "Store Asset Register" temporary;
                    GeneratedCount: Integer;
                    SkippedCount: Integer;
                begin
                    // Collect the selected rows into a temporary snapshot and close that
                    // scan BEFORE processing any of them - GenerateTagNo (via
                    // NextSequenceFor) opens its own scan against this same table to find
                    // the next free number, and having that nested inside an already-open,
                    // locked-for-update cursor on the same table is what was crashing the
                    // client. Get() below reads one row at a time instead of holding a
                    // second live cursor open across the whole loop.
                    CurrPage.SetSelectionFilter(AssetRegister);
                    if AssetRegister.FindSet() then
                        repeat
                            SelectedKeys := AssetRegister;
                            SelectedKeys.Insert();
                        until AssetRegister.Next() = 0;

                    if SelectedKeys.FindSet() then
                        repeat
                            AssetRegister.Get(SelectedKeys."Entry No.");
                            // A tag can only be built once the Asset Class is known.
                            if (AssetRegister."Tag No." <> '') or (AssetRegister.Category = '') then
                                SkippedCount += 1
                            else begin
                                GenerateTagNoFor(AssetRegister);
                                GeneratedCount += 1;
                            end;
                        until SelectedKeys.Next() = 0;

                    CurrPage.Update(false);
                    Message(TagsGeneratedMsg, GeneratedCount, SkippedCount);
                end;
            }
            action(TransferAsset)
            {
                ApplicationArea = All;
                Caption = 'Transfer Asset';
                Image = TransferOrder;
                ToolTip = 'Start a transfer for the selected unit: move it to another location, hand it to another employee, or both. The Store Manager confirms it, then it is carried out.';

                trigger OnAction()
                var
                    AssetTransfer: Record "Store Asset Transfer";
                begin
                    Rec.TestField("Tag No.");
                    AssetTransfer.Init();
                    AssetTransfer.Insert(true);
                    AssetTransfer.Validate("Tag No.", Rec."Tag No.");
                    AssetTransfer.Modify(true);
                    Page.Run(Page::"Store Asset Transfer Card", AssetTransfer);
                end;
            }
            action(ShowHistory)
            {
                ApplicationArea = All;
                Caption = 'Issue and Return History';
                Image = History;
                ToolTip = 'Everyone this unit has been issued to, with the dates it was issued and returned.';

                trigger OnAction()
                var
                    EmployeeItem: Record "Employee Items";
                begin
                    EmployeeItem.SetRange("Tag No.", Rec."Tag No.");
                    Page.Run(Page::"Store Issue Return History", EmployeeItem);
                end;
            }
            action(RequestDisposal)
            {
                ApplicationArea = All;
                Caption = 'Request Disposal';
                Image = Delete;
                Enabled = Rec."Disposal Status" <> Rec."Disposal Status"::PendingApproval;
                ToolTip = 'Set the Disposal Method first, then request disposal. Takes effect only once an Asset Disposal Approver approves it.';

                trigger OnAction()
                begin
                    StoreAssetDisposalMgt.RequestDisposal(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(ApproveDisposal)
            {
                ApplicationArea = All;
                Caption = 'Approve Disposal';
                Image = Approve;
                Enabled = Rec."Disposal Status" = Rec."Disposal Status"::PendingApproval;
                ToolTip = 'Approve this pending disposal request. Only available to the Asset Disposal Approver permission set.';

                trigger OnAction()
                begin
                    StoreAssetDisposalMgt.ApproveDisposal(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(RejectDisposal)
            {
                ApplicationArea = All;
                Caption = 'Reject Disposal';
                Image = Reject;
                Enabled = Rec."Disposal Status" = Rec."Disposal Status"::PendingApproval;
                ToolTip = 'Reject this pending disposal request. Only available to the Asset Disposal Approver permission set.';

                trigger OnAction()
                begin
                    StoreAssetDisposalMgt.RejectDisposal(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    // A plain procedure, not a [TryFunction]: this saves the row, and this
    // server refuses to save records inside a try function (the page then
    // shows "Something went wrong"). The one case that used to be swallowed - no
    // Asset Class yet - is checked by the callers before they get here.
    local procedure GenerateTagNoFor(var AssetRegister: Record "Store Asset Register")
    begin
        // GenerateTagNo only Validates the field in memory - fine when called
        // from the table's OnInsert trigger (the row isn't written yet, so the
        // in-progress insert picks it up automatically), but this action runs
        // against rows that already exist, so it needs an explicit Modify to
        // actually save the generated tag.
        StoreAssetTagMgt.GenerateTagNo(AssetRegister);
        AssetRegister.Modify(true);
    end;

    // Turns one row of N units into N rows of 1 unit each. The original row
    // becomes the first unit (keeps its Tag No./Serial No. if it already had
    // one); the rest are new rows that each get their own Tag No. automatically
    // via the table's OnInsert trigger. Serial No. is deliberately not copied
    // to the new rows - one serial number shouldn't be implied for many units.
    local procedure SplitRow(var AssetRegister: Record "Store Asset Register"): Integer
    var
        NewRow: Record "Store Asset Register";
        Prefix: Text[30];
        NextSeq: Integer;
        TotalUnits: Integer;
        i: Integer;
    begin
        if AssetRegister."Physical Count" <> Round(AssetRegister."Physical Count", 1) then
            exit(0);
        TotalUnits := Round(AssetRegister."Physical Count", 1);
        if TotalUnits <= 1 then
            exit(0);

        // Look up the starting tag number ONCE for the whole batch, then just
        // count up in memory for each new row - a plain Insert() would otherwise
        // trigger its own fresh database lookup per row (via auto-tag-on-insert),
        // and a big split (dozens or hundreds of units) turned that into enough
        // round-trips to time the request out. Setting Tag No. directly before
        // Insert makes the auto-tag check on OnInsert a no-op (it only acts when
        // Tag No. is still blank).
        if AssetRegister.Category <> '' then begin
            Prefix := StoreAssetTagMgt.PrefixFor(AssetRegister.Category, AssetRegister."Type");
            NextSeq := StoreAssetTagMgt.StartSequenceFor(AssetRegister.Category, AssetRegister."Type");
        end;

        for i := 1 to TotalUnits - 1 do begin
            // Clear(), not Init() - Init() leaves the primary key ("Entry No.")
            // untouched, so reusing NewRow across iterations would carry the
            // previous iteration's assigned Entry No. into the next Insert and
            // collide with it. Clear() resets the primary key too.
            Clear(NewRow);
            NewRow.Category := AssetRegister.Category;
            NewRow."Type" := AssetRegister."Type";
            NewRow.Description := AssetRegister.Description;
            NewRow."Location Code" := AssetRegister."Location Code";
            NewRow."Zone Code" := AssetRegister."Zone Code";
            NewRow."Shelf No." := AssetRegister."Shelf No.";
            NewRow.Model := AssetRegister.Model;
            NewRow."Unit of Measure Code" := AssetRegister."Unit of Measure Code";
            NewRow."Physical Count" := 1;
            NewRow."Program Code" := AssetRegister."Program Code";
            NewRow."Unit Cost" := AssetRegister."Unit Cost";
            NewRow.Status := AssetRegister.Status;
            NewRow.Remarks := AssetRegister.Remarks;
            NewRow."PO No." := AssetRegister."PO No.";
            NewRow."Vendor No." := AssetRegister."Vendor No.";
            NewRow."Procured Date" := AssetRegister."Procured Date";
            // Finance creates one Fixed Asset card per purchase regardless of
            // quantity, so every unit split out of this row still maps back to
            // that same shared card - not a new one each.
            NewRow."Fixed Asset No." := AssetRegister."Fixed Asset No.";
            if AssetRegister.Category <> '' then begin
                NewRow."Tag No." := StoreAssetTagMgt.BuildTagNo(Prefix, NextSeq);
                NextSeq += 1;
            end;
            NewRow.Insert(true);
        end;

        AssetRegister."Physical Count" := 1;
        // The new rows above were tagged as they were inserted, but this original
        // row is only being modified, so that never fires for it: give it its tag
        // now (after the new rows exist, so it takes the next free number) and
        // save the count and the tag together.
        if (AssetRegister."Tag No." = '') and (AssetRegister.Category <> '') then
            StoreAssetTagMgt.GenerateTagNo(AssetRegister);
        AssetRegister.Modify(true);
        exit(TotalUnits - 1);
    end;

    var
        StoreAssetTagMgt: Codeunit "Store Asset Tag Mgt.";
        StoreAssetDisposalMgt: Codeunit "Store Asset Disposal Mgt.";
        TagsGeneratedMsg: Label '%1 tag number(s) generated, %2 skipped (already tagged, or missing an Asset Class).', Comment = '%1 = generated count, %2 = skipped count';
        SplitResultMsg: Label '%1 additional unit row(s) created, %2 row(s) skipped (Physical Count of 1 or less, or a fractional count).', Comment = '%1 = units created, %2 = rows skipped';
}

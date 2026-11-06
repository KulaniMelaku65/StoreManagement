page 60172 "Store Asset Transfer Card"
{
    PageType = Card;
    SourceTable = "Store Asset Transfer";
    Caption = 'Asset Transfer';

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                }
            }
            group(Asset)
            {
                Caption = 'Asset';

                field("Tag No."; Rec."Tag No.")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Open;
                    ToolTip = 'The tagged unit being moved. Pick it from the Asset Register.';

                    // The built-in lookup can only return a primary key field, and
                    // Tag Number is not the key of the Asset Register, so open the
                    // register ourselves and take the tag from the row picked.
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        AssetRegister: Record "Store Asset Register";
                        AssetRegisterList: Page "Store Asset Lookup";
                    begin
                        AssetRegister.SetFilter("Availability Status", '<>%1', AssetRegister."Availability Status"::Disposed);
                        AssetRegisterList.SetTableView(AssetRegister);
                        AssetRegisterList.LookupMode(true);
                        if AssetRegisterList.RunModal() = Action::LookupOK then begin
                            AssetRegisterList.GetRecord(AssetRegister);
                            Text := AssetRegister."Tag No.";
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Model; Rec.Model)
                {
                    ApplicationArea = All;
                }
                field("From Location Code"; Rec."From Location Code")
                {
                    ApplicationArea = All;
                }
                field("From Holder"; Rec."From Holder")
                {
                    ApplicationArea = All;
                    ToolTip = 'Who holds the asset right now. Blank means it is in the store.';
                }
            }
            group(Destination)
            {
                Caption = 'Move To';

                field("To Location Code"; Rec."To Location Code")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field("To Zone Code"; Rec."To Zone Code")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field("To Shelf No."; Rec."To Shelf No.")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field("To Employee No."; Rec."To Employee No.")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Open;
                    ToolTip = 'Hand the asset to another employee. Only for an asset that is already issued to someone.';
                }
                field("To Employee Name"; Rec."To Employee Name")
                {
                    ApplicationArea = All;
                }
                field(Reason; Rec.Reason)
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Open;
                }
                field("Expected Back"; Rec."Expected Back")
                {
                    ApplicationArea = All;
                    Editable = Rec.Status = Rec.Status::Open;
                }
            }
            group(Tracking)
            {
                Caption = 'Tracking';

                field("Created By"; Rec."Created By")
                {
                    ApplicationArea = All;
                }
                field("Confirmed By"; Rec."Confirmed By")
                {
                    ApplicationArea = All;
                }
                field("Confirmed Date"; Rec."Confirmed Date")
                {
                    ApplicationArea = All;
                }
                field("Transferred By"; Rec."Transferred By")
                {
                    ApplicationArea = All;
                }
                field("Transferred Date"; Rec."Transferred Date")
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
            action(ConfirmTransfer)
            {
                ApplicationArea = All;
                Caption = 'Confirm Transfer';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = Rec.Status = Rec.Status::Open;
                ToolTip = 'Store Manager only: confirm this transfer so the store keeper can carry it out. You cannot confirm your own.';

                trigger OnAction()
                var
                    StoreAssetTransferMgt: Codeunit "Store Asset Transfer Mgt.";
                begin
                    StoreAssetTransferMgt.Confirm(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CarryOutTransfer)
            {
                ApplicationArea = All;
                Caption = 'Transfer';
                Image = TransferOrder;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Enabled = Rec.Status = Rec.Status::Confirmed;
                ToolTip = 'Carry out the confirmed transfer: update the Asset Register and, for a change of holder, the custody records.';

                trigger OnAction()
                var
                    StoreAssetTransferMgt: Codeunit "Store Asset Transfer Mgt.";
                begin
                    StoreAssetTransferMgt.Transfer(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
    }
}

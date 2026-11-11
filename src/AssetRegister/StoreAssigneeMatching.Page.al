page 60179 "Store Assignee Matching"
{
    Caption = 'Assigned To Name Matching';
    PageType = Worksheet;
    SourceTable = "Store Assignee Match";
    SourceTableView = sorting("Match Score") order(descending);
    UsageCategory = Tasks;
    ApplicationArea = All;
    InsertAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Lines)
            {
                field("Assigned To"; Rec."Assigned To")
                {
                    ApplicationArea = All;
                    ToolTip = 'The name as it was typed in Assigned To on the Asset Register.';
                }
                field("Asset Count"; Rec."Asset Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'How many assets carry this name and are not yet linked.';

                    trigger OnDrillDown()
                    var
                        AssetRegister: Record "Store Asset Register";
                    begin
                        AssetRegister.SetRange("Availability Status", AssetRegister."Availability Status"::Available);
                        AssetRegister.SetRange("Assigned To", Rec."Assigned To");
                        Page.Run(Page::"Store Asset Register List", AssetRegister);
                    end;
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = All;
                    StyleExpr = ScoreStyle;
                    ToolTip = 'The employee these assets will be linked to. Change it if the suggestion is wrong; clear it to leave this name unlinked.';
                }
                field("Employee Name"; Rec."Employee Name")
                {
                    ApplicationArea = All;
                    StyleExpr = ScoreStyle;
                    ToolTip = 'The name on the Employee card, to compare with what was typed.';
                }
                field("Match Score"; Rec."Match Score")
                {
                    ApplicationArea = All;
                    StyleExpr = ScoreStyle;
                    ToolTip = 'How closely the typed name matches the employee''s name. 100 means the same words.';
                }
                field("Match Basis"; Rec."Match Basis")
                {
                    ApplicationArea = All;
                    ToolTip = 'Why this employee was suggested, or what to check.';
                }
                field("Runner-up"; Rec."Runner-up")
                {
                    ApplicationArea = All;
                    ToolTip = 'The second-closest employee. When this is close to the suggestion, check which one really has the asset.';
                }
                field(Accepted; Rec.Accepted)
                {
                    ApplicationArea = All;
                    ToolTip = 'Tick once you are satisfied the employee is right. Only accepted rows are linked.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SuggestMatches)
            {
                ApplicationArea = All;
                Caption = 'Suggest Matches';
                Image = Suggest;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Rebuild this list from the Asset Register: every Assigned To name not yet linked, with the closest employee. Replaces any choices made here that have not been linked yet.';

                trigger OnAction()
                begin
                    if not Rec.IsEmpty() then
                        if not Confirm(RebuildQst, false) then
                            exit;
                    StoreAssigneeMatchMgt.SuggestMatches();
                    CurrPage.Update(false);
                end;
            }
            action(AcceptHigh)
            {
                ApplicationArea = All;
                Caption = 'Accept 90% and Above';
                Image = Approve;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Tick Accepted on every row scoring 90% or more. Look down the list first - a high score is very likely, not certain.';

                trigger OnAction()
                begin
                    Message(AcceptedMsg, StoreAssigneeMatchMgt.AcceptHighScores(90));
                    CurrPage.Update(false);
                end;
            }
            action(LinkAccepted)
            {
                ApplicationArea = All;
                Caption = 'Link Accepted';
                Image = LinkAccount;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Record the assets of every accepted row as issued to the chosen employee. Linked rows leave this list; the rest stay for later.';

                trigger OnAction()
                begin
                    StoreAssigneeMatchMgt.LinkAccepted();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        case true of
            Rec."Employee No." = '':
                ScoreStyle := 'Subordinate';
            Rec."Match Score" >= 90:
                ScoreStyle := 'Favorable';
            Rec."Match Score" >= 75:
                ScoreStyle := 'Ambiguous';
            else
                ScoreStyle := 'Unfavorable';
        end;
    end;

    var
        StoreAssigneeMatchMgt: Codeunit "Store Assignee Match Mgt.";
        ScoreStyle: Text;
        RebuildQst: Label 'Rebuild the list? Choices you made here that have not been linked yet will be lost.';
        AcceptedMsg: Label '%1 rows accepted.', Comment = '%1 = number of rows';
}

codeunit 60180 "Store Assignee Match Mgt."
{
    // Suggests the closest employee for each "Assigned To" name that did not
    // match exactly - spelling mistakes, a missing or extra name, names in a
    // different order, titles such as Mr/Dr/Ato/W/ro. Nothing is linked here:
    // the suggestions go to the "Assigned To Name Matching" worksheet, a person
    // accepts or corrects them, and only accepted rows are linked.
    //
    // How the score works: both names are split into words. Each word of the
    // typed name is paired with the most similar unused word of the employee's
    // name (similarity = 1 - edit distance / longer length, so "Tesfay" vs
    // "Tesfaye" is 0.86), and the score is the average over the typed words.
    // A single typed word is too weak to trust, so its score is capped at 60.
    Permissions = tabledata "Store Assignee Match" = RIMD, tabledata "Store Asset Register" = RM, tabledata "Employee Items" = RIM, tabledata Employee = R, tabledata "Fixed Asset" = R;

    procedure SuggestMatches()
    var
        AssigneeMatch: Record "Store Assignee Match";
        AssetRegister: Record "Store Asset Register";
        Employee: Record Employee;
        EmpNos: List of [Code[20]];
        EmpWords: List of [Text];
        NameCounts: Dictionary of [Text, Integer];
        NameAsTyped: Dictionary of [Text, Text];
        UpperName: Text;
        TypedWords: List of [Text];
        Window: Dialog;
        i: Integer;
        Done: Integer;
        Score: Decimal;
        BestScore: Decimal;
        SecondScore: Decimal;
        BestNo: Code[20];
        SecondNo: Code[20];
        EntryNo: Integer;
    begin
        AssigneeMatch.DeleteAll();

        // Distinct names still waiting to be linked, with how many assets each.
        AssetRegister.SetRange("Availability Status", AssetRegister."Availability Status"::Available);
        AssetRegister.SetFilter("Assigned To", '<>%1', '');
        if AssetRegister.FindSet() then
            repeat
                UpperName := UpperCase(DelChr(AssetRegister."Assigned To", '<>', ' '));
                if NameCounts.ContainsKey(UpperName) then
                    NameCounts.Set(UpperName, NameCounts.Get(UpperName) + 1)
                else begin
                    NameCounts.Add(UpperName, 1);
                    NameAsTyped.Add(UpperName, AssetRegister."Assigned To");
                end;
            until AssetRegister.Next() = 0;
        if NameCounts.Count() = 0 then begin
            Message(NothingToMatchMsg);
            exit;
        end;

        // Each employee's name words, kept as one '|'-joined string per employee.
        if Employee.FindSet() then
            repeat
                EmpNos.Add(Employee."No.");
                EmpWords.Add(JoinWords(Tokenize(Employee."First Name" + ' ' + Employee."Middle Name" + ' ' + Employee."Last Name")));
            until Employee.Next() = 0;

        if GuiAllowed() then
            Window.Open(ProgressTxt);
        foreach UpperName in NameCounts.Keys() do begin
            Done += 1;
            if GuiAllowed() and (Done mod 10 = 0) then begin
                Window.Update(1, Done);
                Window.Update(2, NameCounts.Count());
            end;

            TypedWords := Tokenize(NameAsTyped.Get(UpperName));
            BestScore := 0;
            SecondScore := 0;
            BestNo := '';
            SecondNo := '';
            for i := 1 to EmpNos.Count() do begin
                Score := ScoreNames(TypedWords, SplitWords(EmpWords.Get(i)));
                if Score > BestScore then begin
                    SecondScore := BestScore;
                    SecondNo := BestNo;
                    BestScore := Score;
                    BestNo := EmpNos.Get(i);
                end else
                    if Score > SecondScore then begin
                        SecondScore := Score;
                        SecondNo := EmpNos.Get(i);
                    end;
            end;

            EntryNo += 1;
            InsertSuggestion(EntryNo, CopyStr(NameAsTyped.Get(UpperName), 1, 100), NameCounts.Get(UpperName),
                TypedWords.Count(), BestNo, BestScore, SecondNo, SecondScore);
        end;
        if GuiAllowed() then
            Window.Close();
    end;

    procedure AcceptHighScores(MinScore: Integer): Integer
    var
        AssigneeMatch: Record "Store Assignee Match";
        AcceptedCount: Integer;
    begin
        AssigneeMatch.SetFilter("Match Score", '>=%1', MinScore);
        AssigneeMatch.SetFilter("Employee No.", '<>%1', '');
        AssigneeMatch.SetRange(Accepted, false);
        if AssigneeMatch.FindSet(true) then
            repeat
                AssigneeMatch.Accepted := true;
                AssigneeMatch.Modify();
                AcceptedCount += 1;
            until AssigneeMatch.Next() = 0;
        exit(AcceptedCount);
    end;

    procedure LinkAccepted()
    var
        AssigneeMatch: Record "Store Assignee Match";
        StoreAssetCustodyLinkMgt: Codeunit "Store Asset Custody Link Mgt.";
        LinkedCount: Integer;
        NamesDone: Integer;
        NoTagCount: Integer;
    begin
        AssigneeMatch.SetRange(Accepted, true);
        AssigneeMatch.SetFilter("Employee No.", '<>%1', '');
        if AssigneeMatch.IsEmpty() then
            Error(NothingAcceptedErr);
        if not Confirm(LinkQst, false, AssigneeMatch.Count()) then
            exit;

        if AssigneeMatch.FindSet(true) then
            repeat
                LinkedCount += StoreAssetCustodyLinkMgt.LinkAssetsForName(AssigneeMatch."Assigned To", AssigneeMatch."Employee No.", NoTagCount);
                NamesDone += 1;
                AssigneeMatch.Delete();
            until AssigneeMatch.Next() = 0;

        Message(LinkedMsg, LinkedCount, NamesDone, NoTagCount);
    end;

    local procedure InsertSuggestion(EntryNo: Integer; AssignedTo: Text[100]; AssetCount: Integer; TypedWordCount: Integer; BestNo: Code[20]; BestScore: Decimal; SecondNo: Code[20]; SecondScore: Decimal)
    var
        AssigneeMatch: Record "Store Assignee Match";
        StoreEmployeeNameMgt: Codeunit "Store Employee Name Mgt.";
        ScorePct: Integer;
        SecondPct: Integer;
        IsTie: Boolean;
    begin
        ScorePct := Round(BestScore * 100, 1);
        SecondPct := Round(SecondScore * 100, 1);

        AssigneeMatch.Init();
        AssigneeMatch."Entry No." := EntryNo;
        AssigneeMatch."Assigned To" := AssignedTo;
        AssigneeMatch."Asset Count" := AssetCount;
        // Below 50% the "closest" employee is usually just noise (a room, a
        // department, a former staff member) - leave it blank for a person to fill.
        // A single word ("Nile", "Floor", "Cafe") is almost always a place too.
        // When two employees fit (almost) equally - "Yohannes Molla" is both
        // Yohannes Molla Malede and Yohannes Molla Ayalew - picking one would be
        // a coin toss, so neither is filled in and both are named for a person.
        IsTie := (SecondNo <> '') and (ScorePct - SecondPct < 10) and (ScorePct >= 50);
        AssigneeMatch."Match Score" := ScorePct;
        if (ScorePct >= 50) and (TypedWordCount > 1) and not IsTie then begin
            AssigneeMatch."Employee No." := BestNo;
            AssigneeMatch."Employee Name" := StoreEmployeeNameMgt.FullName(BestNo);
        end;
        if SecondNo <> '' then
            AssigneeMatch."Runner-up" := CopyStr(StrSubstNo(RunnerUpTxt, StoreEmployeeNameMgt.FullName(SecondNo), SecondNo, SecondPct), 1, MaxStrLen(AssigneeMatch."Runner-up"));

        case true of
            TypedWordCount = 1:
                AssigneeMatch."Match Basis" := OneWordTxt;
            ScorePct < 50:
                AssigneeMatch."Match Basis" := NoGoodMatchTxt;
            IsTie:
                AssigneeMatch."Match Basis" := CopyStr(StrSubstNo(EqualFitTxt,
                    StoreEmployeeNameMgt.FullName(BestNo), BestNo, StoreEmployeeNameMgt.FullName(SecondNo), SecondNo),
                    1, MaxStrLen(AssigneeMatch."Match Basis"));
            ScorePct = 100:
                AssigneeMatch."Match Basis" := SameWordsTxt;
            else
                AssigneeMatch."Match Basis" := SpellingTxt;
        end;
        // Only a clear winner is pre-ticked; everything else waits for a person.
        AssigneeMatch.Accepted := (ScorePct >= 90) and (ScorePct - SecondPct >= 10) and (TypedWordCount > 1);
        AssigneeMatch.Insert();
    end;

    local procedure ScoreNames(TypedWords: List of [Text]; EmployeeWords: List of [Text]): Decimal
    var
        Used: List of [Integer];
        TypedWord: Text;
        Total: Decimal;
        Best: Decimal;
        Sim: Decimal;
        BestIndex: Integer;
        j: Integer;
    begin
        if (TypedWords.Count() = 0) or (EmployeeWords.Count() = 0) then
            exit(0);
        foreach TypedWord in TypedWords do begin
            Best := 0;
            BestIndex := 0;
            for j := 1 to EmployeeWords.Count() do
                if not Used.Contains(j) then begin
                    Sim := Similarity(TypedWord, EmployeeWords.Get(j));
                    if Sim > Best then begin
                        Best := Sim;
                        BestIndex := j;
                    end;
                end;
            if BestIndex > 0 then
                Used.Add(BestIndex);
            Total += Best;
        end;
        Total := Total / TypedWords.Count();
        if TypedWords.Count() = 1 then
            if Total > 0.6 then
                Total := 0.6;
        exit(Total);
    end;

    // 1 - Levenshtein distance / length of the longer word.
    local procedure Similarity(A: Text; B: Text): Decimal
    var
        Prev: array[52] of Integer;
        Curr: array[52] of Integer;
        LenA: Integer;
        LenB: Integer;
        i: Integer;
        j: Integer;
        Cost: Integer;
        Best: Integer;
    begin
        if A = B then
            exit(1);
        LenA := StrLen(A);
        LenB := StrLen(B);
        if (LenA = 0) or (LenB = 0) then
            exit(0);
        if LenA > 50 then
            LenA := 50;
        if LenB > 50 then
            LenB := 50;
        for j := 0 to LenB do
            Prev[j + 1] := j;
        for i := 1 to LenA do begin
            Curr[1] := i;
            for j := 1 to LenB do begin
                if A[i] = B[j] then
                    Cost := 0
                else
                    Cost := 1;
                Best := Prev[j + 1] + 1;
                if Curr[j] + 1 < Best then
                    Best := Curr[j] + 1;
                if Prev[j] + Cost < Best then
                    Best := Prev[j] + Cost;
                Curr[j + 1] := Best;
            end;
            CopyArray(Prev, Curr, 1);
        end;
        if LenA > LenB then
            exit(1 - Prev[LenB + 1] / LenA);
        exit(1 - Prev[LenB + 1] / LenB);
    end;

    // Upper-case words, with punctuation and titles removed and the common
    // abbreviations G/ W/ H/ written out, so "Ato G/Medhin T." and
    // "Gebremedhin Tesfaye" can be compared word by word.
    local procedure Tokenize(Name: Text): List of [Text]
    var
        Words: List of [Text];
        Result: List of [Text];
        Word: Text;
    begin
        Name := UpperCase(Name);
        Name := Name.Replace('W/RO', ' ').Replace('W/T', ' ');
        Name := Name.Replace('G/', 'GEBRE').Replace('W/', 'WOLDE').Replace('H/', 'HAILE');
        Name := Name.Replace('-', '').Replace('''', '');
        Name := ConvertStr(Name, '.,;:/\()[]_&', '            ');
        Words := Name.Split(' ');
        foreach Word in Words do
            if (Word <> '') and not IsTitle(Word) then
                Result.Add(Word);
        exit(Result);
    end;

    local procedure IsTitle(Word: Text): Boolean
    begin
        exit(Word in ['MR', 'MRS', 'MS', 'MISS', 'DR', 'PROF', 'ENG', 'ATO', 'WRO', 'WT', 'SR', 'SIR']);
    end;

    local procedure JoinWords(Words: List of [Text]): Text
    var
        Word: Text;
        Result: Text;
    begin
        foreach Word in Words do
            if Result = '' then
                Result := Word
            else
                Result := Result + '|' + Word;
        exit(Result);
    end;

    local procedure SplitWords(Joined: Text): List of [Text]
    var
        Empty: List of [Text];
    begin
        if Joined = '' then
            exit(Empty);
        exit(Joined.Split('|'));
    end;

    var
        ProgressTxt: Label 'Comparing names with employees...\#1###### of #2######';
        NothingToMatchMsg: Label 'Every asset with an Assigned To name is already linked to an employee.';
        NothingAcceptedErr: Label 'No rows are accepted yet. Tick Accepted on the rows you have checked, or choose the right Employee No.';
        LinkQst: Label 'Link the assets for %1 accepted names to the chosen employees?', Comment = '%1 = number of names';
        LinkedMsg: Label '%1 assets linked for %2 names. %3 skipped because they have no Tag Number.', Comment = '%1 = assets linked, %2 = names, %3 = no tag';
        RunnerUpTxt: Label '%1 (%2) - %3%', Comment = '%1 = employee name, %2 = employee no., %3 = score';
        NoGoodMatchTxt: Label 'No close match - choose the employee, or leave it';
        OneWordTxt: Label 'Only one word - probably a place; choose the employee if it is a person';
        EqualFitTxt: Label 'Two employees fit equally: %1 (%2) or %3 (%4) - choose the right one', Comment = '%1/%3 = employee names, %2/%4 = employee numbers';
        SameWordsTxt: Label 'Same names, different order or extra name';
        SpellingTxt: Label 'Spelling differs slightly';
}

codeunit 60167 "Store Greeting Mgt."
{
    // Builds the line at the top of the home page, e.g.
    // "Good afternoon, Kulani Melaku" and, separately, "Role: Store Keeper".
    // The user's full name is read from the User table here, because only this
    // codeunit is given that permission - the store roles themselves don't get
    // access to the User table.
    Permissions = tabledata User = R, tabledata "All Profile" = R, tabledata "User Personalization" = R;

    procedure Greeting(): Text
    begin
        exit(StrSubstNo(GreetingTxt, TimeOfDayGreeting(), UserDisplayName()));
    end;

    // One line for the headline: the greeting with the role in brackets, e.g.
    // "Good morning, Kulani Melaku (Store Keeper)". A Business Central headline
    // rotates between its lines, so the role has to live in the same text.
    procedure GreetingWithRole(): Text
    begin
        exit(StrSubstNo(GreetingRoleTxt, TimeOfDayGreeting(), UserDisplayName(), CurrentRoleName()));
    end;

    // The role the user is working in right now (the Role they picked in My
    // Settings), not what their permissions allow. A manager signed in with the
    // Store Keeper role sees Store Keeper.
    local procedure CurrentRoleName(): Text
    var
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        StoreReqApprovalMgt: Codeunit "Store Req. Approval Mgt.";
    begin
        if ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile) then
            case AllProfile."Profile ID" of
                'STORE MANAGER':
                    exit(ManagerRoleTxt);
                'STORE KEEPER':
                    exit(KeeperRoleTxt);
                else
                    if AllProfile.Description <> '' then
                        exit(AllProfile.Description);
            end;
        // Fall back to what the user's permissions say.
        if StoreReqApprovalMgt.IsStoreManager() then
            exit(ManagerRoleTxt);
        exit(KeeperRoleTxt);
    end;

    local procedure UserDisplayName(): Text
    var
        User: Record User;
    begin
        User.SetRange("User Name", UserId());
        if User.FindFirst() then
            if User."Full Name" <> '' then
                exit(User."Full Name");
        exit(UserId());
    end;

    local procedure TimeOfDayGreeting(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        LocalNow: DateTime;
        Hour: Integer;
    begin
        // The user's own time zone (My Settings), not the server's.
        LocalNow := TypeHelper.GetCurrentDateTimeInUserTimeZone();
        if not Evaluate(Hour, Format(DT2Time(LocalNow), 0, '<Hours24>')) then
            exit(GoodDayTxt);
        case true of
            Hour < 12:
                exit(MorningTxt);
            Hour < 17:
                exit(AfternoonTxt);
            else
                exit(EveningTxt);
        end;
    end;

    var
        GreetingTxt: Label '%1, %2', Comment = '%1 = Good morning/afternoon/evening, %2 = full name';
        GreetingRoleTxt: Label '%1, %2 (%3)', Comment = '%1 = Good morning/afternoon/evening, %2 = full name, %3 = role';
        MorningTxt: Label 'Good morning';
        AfternoonTxt: Label 'Good afternoon';
        EveningTxt: Label 'Good evening';
        GoodDayTxt: Label 'Welcome';
        ManagerRoleTxt: Label 'Store Manager';
        KeeperRoleTxt: Label 'Store Keeper';
}

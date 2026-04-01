pageextension 50604 "ResourceCapacity Opt." extends "Resource Capacity"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

    procedure ResourceFilter(pResFilter: Text)
    begin
        CurrPage.MatrixForm.PAGE.ResourceFilter(pResFilter);
    end;
}
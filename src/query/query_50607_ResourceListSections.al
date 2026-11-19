query 50607 "Opti Resource List Sections"
{
    QueryType = Normal;
    Caption = 'Resource List Sections';

    elements
    {
        dataitem(Resource; Resource)
        {
            filter(Resource_Group_No_Filter; "Resource Group No.")
            {
            }
            filter(MandatoryFilter; "Opti Mandatory Schedulling")
            {
            }
            column(No_; "No.")
            {
            }
            column(Name; Name)
            {
            }
            column(Resource_Group_No_; "Resource Group No.")
            {
            }
            column(Pool_Resource_No_; "Opti Pool Resource No.")
            {
            }
            column(Mandatory_Schedulling; "Opti Mandatory Schedulling")
            {
            }

            dataitem(Res__Capacity_Entry; "Res. Capacity Entry")
            {
                DataItemLink = "Resource No." = Resource."No.";
                SqlJoinType = LeftOuterJoin;

                filter(EntryDateFilter; "Date")
                {
                }
                column(CapacityEntryCount)
                {
                    Method = Count;
                }
            }
        }
    }

    var
        myInt: Integer;

    trigger OnBeforeOpen()
    begin

    end;
}

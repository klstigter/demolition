table 61290 MyTable
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; MyField; Integer)
        {
            DataClassification = ToBeClassified;

        }

    }

    keys
    {
        key(Key1; MyField)
        {
            Clustered = true;
        }
    }





}
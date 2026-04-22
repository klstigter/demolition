tableextension 50617 "Opt. Job Journal Line" extends "Job Journal Line"
{
    // Adds a lightweight signal field used exclusively by the API subpage.
    // When the caller sets "triggerPost": true on the LAST line in the JSON array,
    // OnInsertRecord in page 50623 posts the entire batch in one Job Jnl.-Post Batch run,
    // producing a SINGLE Job Register entry for all lines (native BC behaviour).
    // The field is never read by standard BC code and is deleted with the line after posting.
    fields
    {
        field(50617; "Opt. Trigger Post"; Boolean)
        {
            Caption = 'Trigger Post';
            DataClassification = SystemMetadata;
        }
    }
}

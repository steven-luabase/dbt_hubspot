{{ config(enabled=fivetran_utils.enabled_vars(['hubspot_sales_enabled','hubspot_deal_enabled'])) }}

with deals as (

    select *
    from {{ var('deal') }}

), pipelines as (

    select *
    from {{ var('deal_pipeline') }}

), pipeline_stages as (

    select *
    from {{ var('deal_pipeline_stage') }}

), owners as (

    select *
    from {{ var('owner') }}

), contacts as (

    select 
        deal_id,
        array_agg(contact_id) as contact_ids
    from {{ var('deal_contact')}}
    group by deal_id

), companies as (

    select 
        deal_id,
        array_agg(company_id) as company_ids
    from {{ var('deal_company') }}
    group by deal_id

),


deal_fields_joined as (

    select 
        deals.*,
        coalesce(pipelines.is_deal_pipeline_deleted, false) as is_deal_pipeline_deleted,
        pipelines.pipeline_label,
        pipelines.is_active as is_pipeline_active,
        coalesce(pipeline_stages.is_deal_pipeline_stage_deleted, false) as is_deal_pipeline_stage_deleted,
        pipelines.deal_pipeline_created_at,
        pipelines.deal_pipeline_updated_at,
        pipeline_stages.pipeline_stage_label,
        owners.email_address as owner_email_address,
        owners.full_name as owner_full_name,
        contacts.contact_ids[0] as primary_contact_id,
        companies.company_ids[0] as primary_company_id,
        contacts.contact_ids,
        companies.company_ids
    from deals    
    left join pipelines 
        on deals.deal_pipeline_id = pipelines.deal_pipeline_id
    left join pipeline_stages 
        on deals.deal_pipeline_stage_id = pipeline_stages.deal_pipeline_stage_id
    left join owners 
        on deals.owner_id = owners.owner_id
    left join contacts
        on deals.deal_id = contacts.deal_id 
    left join companies
        on deals.deal_id = companies.deal_id
)

select *
from deal_fields_joined
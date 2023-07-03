{{ config(enabled=fivetran_utils.enabled_vars(['hubspot_sales_enabled','hubspot_deal_enabled'])) }}

with deals_enhanced as (

    select *
    from {{ ref('int_hubspot__deals_enhanced') }}

{% if fivetran_utils.enabled_vars(['hubspot_engagement_enabled','hubspot_engagement_deal_enabled']) %}

), engagements as (

    select *
    from {{ ref('hubspot__engagements') }}

), engagement_deals as (

    select *
    from {{ var('engagement_deal') }}

), engagement_deal_joined as (

    select
        engagements.engagement_type,
        engagement_deals.deal_id
    from engagements
    inner join engagement_deals
        using (engagement_id)

), engagement_deal_agg as (

    {{ engagements_aggregated('engagement_deal_joined', 'deal_id') }}

), engagements_joined as (

    select 
        deals_enhanced.*,
        {% for metric in engagement_metrics() %}
        coalesce(engagement_deal_agg.{{ metric }},0) as {{ metric }} {% if not loop.last %},{% endif %}
        {% endfor %}
    from deals_enhanced
    left join engagement_deal_agg
        using (deal_id)

), last_engaged as (
    select 
        deal_ids[0] as deal_id,
        max(occurred_timestamp) as last_engagement_at
    from {{ ref('hubspot__engagements') }} 
    where deal_ids is not null
    and engagement_type = 'EMAIL'
    group by deal_id
)

select 
    engagements_joined.*,
    last_engaged.last_engagement_at
from engagements_joined
left join last_engaged
    on engagements_joined.deal_id = last_engaged.deal_id

{% else %}

)

select *
from deals_enhanced

{% endif %}
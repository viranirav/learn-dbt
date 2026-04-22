with source as (
    select * from {{ ref('locations') }}
)

select
    location_id,
    street_address,
    city,
    state,
    country
from source

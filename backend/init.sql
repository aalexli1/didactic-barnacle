-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Create spatial indexes function
CREATE OR REPLACE FUNCTION create_spatial_indexes() RETURNS void AS $$
BEGIN
    -- This will be called after tables are created by Sequelize
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'treasures') THEN
        CREATE INDEX IF NOT EXISTS idx_treasures_location ON treasures USING GIST (location);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Add some helper functions for distance calculations
CREATE OR REPLACE FUNCTION calculate_distance(
    lat1 FLOAT, lon1 FLOAT,
    lat2 FLOAT, lon2 FLOAT
) RETURNS FLOAT AS $$
BEGIN
    RETURN ST_Distance(
        ST_SetSRID(ST_MakePoint(lon1, lat1), 4326)::geography,
        ST_SetSRID(ST_MakePoint(lon2, lat2), 4326)::geography
    );
END;
$$ LANGUAGE plpgsql;

-- Function to get nearby treasures
CREATE OR REPLACE FUNCTION get_nearby_treasures(
    user_lat FLOAT,
    user_lon FLOAT,
    radius_meters FLOAT
) RETURNS TABLE (
    id UUID,
    title VARCHAR,
    distance FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.title,
        ST_Distance(
            t.location::geography,
            ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography
        ) as distance
    FROM treasures t
    WHERE ST_DWithin(
        t.location::geography,
        ST_SetSRID(ST_MakePoint(user_lon, user_lat), 4326)::geography,
        radius_meters
    )
    AND t.is_active = true
    ORDER BY distance;
END;
$$ LANGUAGE plpgsql;
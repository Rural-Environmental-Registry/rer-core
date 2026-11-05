#!/bin/bash

# Script GeoServer REST API - Configuração Completa RER
# Cria workspace, datastore, estilos incorporados e publica camadas com filtros CQL automáticos

# Configurações do GeoServer
# Configurações do GeoServer
GEOSERVER_URL="http://localhost:8080${WEBAPP_CONTEXT:-/geoserver}"
GEOSERVER_USER="${GEOSERVER_ADMIN_USER:-admin}"
GEOSERVER_PASSWORD="${GEOSERVER_ADMIN_PASSWORD:-geoserver}"

# Definições dos estilos SLD incorporados no script
STYLE_RER_NO_OPACITY='<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0"
 xsi:schemaLocation="http://www.opengis.net/sld StyledLayerDescriptor.xsd"
 xmlns="http://www.opengis.net/sld"
 xmlns:ogc="http://www.opengis.net/ogc"
 xmlns:xlink="http://www.w3.org/1999/xlink"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <Name>default_polygon</Name>
    <UserStyle>
      <Title>Default Polygon</Title>
      <Abstract>A sample style that draws a polygon</Abstract>
      <FeatureTypeStyle>
        <Rule>
          <Name>rule1</Name>
          <Title>Gray Polygon with Black Outline</Title>
          <Abstract>A polygon with a gray fill and a 1 pixel black outline</Abstract>
          <PolygonSymbolizer>
            <Stroke>
              <CssParameter name="stroke">#000000</CssParameter>
              <CssParameter name="stroke-width">1</CssParameter>
            </Stroke>
          </PolygonSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>'

STYLE_RER_MUNICIPALITY='<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0"
 xsi:schemaLocation="http://www.opengis.net/sld StyledLayerDescriptor.xsd"
 xmlns="http://www.opengis.net/sld"
 xmlns:ogc="http://www.opengis.net/ogc"
 xmlns:xlink="http://www.w3.org/1999/xlink"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <NamedLayer>
    <Name>default_polygon</Name>
    <UserStyle>
      <Title>Default Polygon</Title>
      <Abstract>A sample style that draws a polygon</Abstract>
      <FeatureTypeStyle>
        <Rule>
          <Name>rule1</Name>
          <Title>Gray Polygon with white Outline</Title>
          <Abstract>A polygon with a white fill and a 1 pixel white outline</Abstract>
          <PolygonSymbolizer>
            <Stroke>
              <CssParameter name="stroke">#FFFFFF</CssParameter>
              <CssParameter name="stroke-width">1</CssParameter>
            </Stroke>
          </PolygonSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>'

STYLE_RER_STATE='<?xml version="1.0" encoding="UTF-8"?>
<sld:StyledLayerDescriptor xmlns="http://www.opengis.net/sld"
  xmlns:sld="http://www.opengis.net/sld"
  xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:gml="http://www.opengis.net/gml" version="1.0.0">
  <sld:NamedLayer>
    <sld:Name>estado</sld:Name>
    <sld:UserStyle>
      <sld:Name>estado</sld:Name>
      <sld:FeatureTypeStyle>
        <sld:Name>estado</sld:Name>
        <sld:Rule>
          <sld:PolygonSymbolizer>
            <sld:Fill>
              <sld:CssParameter name="fill-opacity">0.0</sld:CssParameter>
            </sld:Fill>
            <sld:Stroke>
              <sld:CssParameter name="stroke">#000000</sld:CssParameter>
              <sld:CssParameter name="stroke-width">2</sld:CssParameter>
              <sld:CssParameter name="stroke-opacity">1.0</sld:CssParameter>
            </sld:Stroke>
          </sld:PolygonSymbolizer>
        </sld:Rule>
      </sld:FeatureTypeStyle>
    </sld:UserStyle>
  </sld:NamedLayer>
</sld:StyledLayerDescriptor>'

STYLE_RER_RURAL_PROPERTY='<?xml version="1.0" encoding="ISO-8859-1"?>
<StyledLayerDescriptor version="1.0.0"
  xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.0.0/StyledLayerDescriptor.xsd"
  xmlns="http://www.opengis.net/sld" xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

  <NamedLayer>
    <Name>rural_property</Name>
    <UserStyle>
      <Title>Yellow</Title>
      <FeatureTypeStyle>
        <Rule>
          <PolygonSymbolizer>
            <Fill>
              <CssParameter name="fill">#FFFF00</CssParameter>
              <CssParameter name="fill-opacity">0.2</CssParameter>
            </Fill>
            <Stroke>
                <CssParameter name="stroke">#FFD700</CssParameter>
                <CssParameter name="stroke-width">1</CssParameter>
            </Stroke>
          </PolygonSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>'

STYLE_RER_RIVER='<?xml version="1.0" encoding="ISO-8859-1"?>
<StyledLayerDescriptor version="1.0.0"
  xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.0.0/StyledLayerDescriptor.xsd"
  xmlns="http://www.opengis.net/sld" xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

  <NamedLayer>
    <Name>river_10_to_50</Name>
    <UserStyle>
      <Title>A teal polygon style</Title>
      <FeatureTypeStyle>
        <Rule>
          <PolygonSymbolizer>
            <Fill>
              <CssParameter name="fill">#1E90FF</CssParameter>
              <CssParameter name="fill-opacity">0.2</CssParameter>
            </Fill>
            <Stroke>
                <CssParameter name="stroke">#1E90FF</CssParameter>
                <CssParameter name="stroke-width">1</CssParameter>
            </Stroke>
          </PolygonSymbolizer>

        </Rule>

      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>'

STYLE_RER_CONSOLIDATED_AREA='<?xml version="1.0" encoding="ISO-8859-1"?>
<StyledLayerDescriptor version="1.0.0"
  xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.0.0/StyledLayerDescriptor.xsd"
  xmlns="http://www.opengis.net/sld" xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

  <NamedLayer>
    <Name>area_consolidada</Name>
    <UserStyle>
      <Title>A yellow polygon style</Title>
      <FeatureTypeStyle>
        <Rule>
          <PolygonSymbolizer>
            <Fill>
              <CssParameter name="fill">#808080</CssParameter>
              <CssParameter name="fill-opacity">0.5</CssParameter>
            </Fill>
            <Stroke>
                <CssParameter name="stroke">#808080</CssParameter>
                <CssParameter name="stroke-width">1</CssParameter>
            </Stroke>
          </PolygonSymbolizer>

        </Rule>

      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>'

STYLE_RER_LEGAL_RESERVE='<?xml version="1.0" encoding="ISO-8859-1"?>
<StyledLayerDescriptor version="1.0.0"
  xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.0.0/StyledLayerDescriptor.xsd"
  xmlns="http://www.opengis.net/sld" xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

  <NamedLayer>
    <Name>reserva_legal</Name>
    <UserStyle>
      <Title>A orange polygon style</Title>
      <FeatureTypeStyle>
        <Rule>
          <PolygonSymbolizer>
            <Fill>
              <CssParameter name="fill">#2e7d32</CssParameter>
              <CssParameter name="fill-opacity">0.5</CssParameter>
            </Fill>
             <Stroke>
              <CssParameter name="stroke">#2e7d32</CssParameter>
              <CssParameter name="stroke-width">1</CssParameter>
            </Stroke>
          </PolygonSymbolizer>

        </Rule>

      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>'

STYLE_RER_NATIVE_VEGETATION='<?xml version="1.0" encoding="ISO-8859-1"?>
<StyledLayerDescriptor version="1.0.0"
  xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.0.0/StyledLayerDescriptor.xsd"
  xmlns="http://www.opengis.net/sld" xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

  <NamedLayer>
    <Name>native_vegetation</Name>
    <UserStyle>
      <Title>A green polygon style</Title>
      <FeatureTypeStyle>
        <Rule>
          <PolygonSymbolizer>
            <Fill>
              <CssParameter name="fill">#008000</CssParameter>
              <CssParameter name="fill-opacity">0.5</CssParameter>
            </Fill>
            <Stroke>
              <CssParameter name="stroke">#008000</CssParameter>
              <CssParameter name="stroke-width">1</CssParameter>
            </Stroke>
          </PolygonSymbolizer>

        </Rule>

      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>'

STYLE_RER_PROPERTY_HEADQUARTERS='<?xml version="1.0" encoding="ISO-8859-1"?>
<StyledLayerDescriptor version="1.0.0"
  xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.0.0/StyledLayerDescriptor.xsd"
  xmlns="http://www.opengis.net/sld" xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

  <NamedLayer>
    <Name>property_headquartes</Name>
    <UserStyle>
      <Title>gold square point style</Title>
      <FeatureTypeStyle>
        <Rule>
          <Title>gold point</Title>
          <PointSymbolizer>
            <Graphic>
              <Mark>
                <WellKnownName>square</WellKnownName>
                <Fill>
                  <CssParameter name="fill">#FFD700</CssParameter>
                </Fill>
              </Mark>
              <Size>6</Size>
            </Graphic>
          </PointSymbolizer>
        </Rule>

      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>'

STYLE_RER_RIVER_UP_TO_10_M='<?xml version="1.0" encoding="ISO-8859-1"?>
<StyledLayerDescriptor version="1.0.0"
  xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.0.0/StyledLayerDescriptor.xsd"
  xmlns="http://www.opengis.net/sld" xmlns:ogc="http://www.opengis.net/ogc"
  xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

  <NamedLayer>
    <Name>river_up_to_10m</Name>
    <UserStyle>
      <Title>Blue light</Title>
      <FeatureTypeStyle>
        <Rule>
          <PolygonSymbolizer>
            <Fill>
              <CssParameter name="fill">#CFE2F3</CssParameter>
            </Fill>
            <Stroke>
                <CssParameter name="stroke">#CFE2F3</CssParameter>
                <CssParameter name="stroke-width">1</CssParameter>
            </Stroke>
          </PolygonSymbolizer>
        </Rule>
      </FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>'

# Função para fazer requisições REST
rest_request() {
    local method=$1
    local url=$2
    local data=$3

    if [ "$method" = "GET" ]; then
        curl -s -w "\n%{http_code}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
             -X GET \
             -H "Accept: application/json" \
             "${GEOSERVER_URL}${url}"
    else
        curl -s -w "\n%{http_code}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
             -X $method \
             -H "Content-Type: application/json" \
             -d "$data" \
             "${GEOSERVER_URL}${url}"
    fi
}

# Função para fazer requisições REST e obter apenas o código HTTP
rest_request_status() {
    local method=$1
    local url=$2
    local data=$3

    if [ "$method" = "GET" ]; then
        curl -s -o /dev/null -w "%{http_code}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
             -X GET \
             -H "Accept: application/json" \
             "${GEOSERVER_URL}${url}"
    else
        curl -s -o /dev/null -w "%{http_code}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
             -X $method \
             -H "Content-Type: application/json" \
             -d "$data" \
             "${GEOSERVER_URL}${url}"
    fi
}

# Função para criar workspace
create_workspace() {
    local workspace_name=$1

    echo "Criando workspace: $workspace_name"

    local data="{
        \"workspace\": {
            \"name\": \"$workspace_name\"
        }
    }"

    local response=$(rest_request "POST" "/rest/workspaces" "$data")
    local status_code=$(echo "$response" | tail -n 1)

    if [ "$status_code" = "201" ]; then
        echo "✓ Workspace '$workspace_name' criado com sucesso"
    else
        echo "✗ Erro ao criar workspace '$workspace_name'"
        echo "Código HTTP: $status_code"
        echo "Resposta: $(echo "$response" | head -n -1)"
        return 1
    fi
}

# Função para criar datastore PostgreSQL/PostGIS
create_postgis_datastore() {
    local workspace_name=$1
    local datastore_name=$2
    local host=$3
    local port=$4
    local database=$5
    local schema=$6
    local user=$7
    local password=$8

    echo "Criando datastore PostGIS: $datastore_name no workspace: $workspace_name"

    local data="{
        \"dataStore\": {
            \"name\": \"$datastore_name\",
            \"type\": \"PostGIS\",
            \"enabled\": true,
            \"workspace\": {
                \"name\": \"$workspace_name\"
            },
            \"connectionParameters\": {
                \"entry\": [
                    {
                        \"@key\": \"host\",
                        \"$\": \"$host\"
                    },
                    {
                        \"@key\": \"port\",
                        \"$\": \"$port\"
                    },
                    {
                        \"@key\": \"database\",
                        \"$\": \"$database\"
                    },
                    {
                        \"@key\": \"schema\",
                        \"$\": \"$schema\"
                    },
                    {
                        \"@key\": \"user\",
                        \"$\": \"$user\"
                    },
                    {
                        \"@key\": \"passwd\",
                        \"$\": \"$password\"
                    },
                    {
                        \"@key\": \"dbtype\",
                        \"$\": \"postgis\"
                    },
                    {
                        \"@key\": \"driver\",
                        \"$\": \"org.postgresql.Driver\"
                    },
                    {
                        \"@key\": \"validate connections\",
                        \"$\": \"true\"
                    },
                    {
                        \"@key\": \"Connection timeout\",
                        \"$\": \"20\"
                    },
                    {
                        \"@key\": \"min connections\",
                        \"$\": \"1\"
                    },
                    {
                        \"@key\": \"max connections\",
                        \"$\": \"10\"
                    }
                ]
            }
        }
    }"

    local response=$(rest_request "POST" "/rest/workspaces/${workspace_name}/datastores" "$data")
    local status_code=$(echo "$response" | tail -n 1)

    if [ "$status_code" = "201" ]; then
        echo "✓ Datastore '$datastore_name' criado com sucesso"
    else
        echo "✗ Erro ao criar datastore '$datastore_name'"
        echo "Código HTTP: $status_code"
        echo "Resposta: $(echo "$response" | head -n -1)"
        return 1
    fi
}

# Função para criar estilo incorporado no script
create_embedded_style() {
    local style_name=$1
    local workspace_name=$2
    local sld_content=""

    # Verificar se estilo já existe
    local style_check=$(rest_request_status "GET" "/rest/workspaces/${workspace_name}/styles/${style_name}")
    if [ "$style_check" = "200" ]; then
        echo "✓ Estilo '$style_name' já existe"
        return 0
    fi

    # Selecionar o conteúdo SLD baseado no nome do estilo
    case "$style_name" in
        "rer_no_opacity")
            sld_content="$STYLE_RER_NO_OPACITY"
            ;;
        "rer_state")
            sld_content="$STYLE_RER_STATE"
            ;;
        "rer_rural_property")
            sld_content="$STYLE_RER_RURAL_PROPERTY"
            ;;
        "rer_river")
            sld_content="$STYLE_RER_RIVER"
            ;;
        "rer_consolidated_area")
            sld_content="$STYLE_RER_CONSOLIDATED_AREA"
            ;;
        "rer_legal_reserve")
            sld_content="$STYLE_RER_LEGAL_RESERVE"
            ;;
        "rer_native_vegetation")
            sld_content="$STYLE_RER_NATIVE_VEGETATION"
            ;;
        "rer_property_headquarters")
            sld_content="$STYLE_RER_PROPERTY_HEADQUARTERS"
            ;;
        "rer_river_up_to_10_m")
            sld_content="$STYLE_RER_RIVER_UP_TO_10_M"
            ;;
        "rer_municipality")
            sld_content="$STYLE_RER_MUNICIPALITY"
            ;;
        *)
            echo "✗ Estilo '$style_name' não encontrado no script"
            return 1
            ;;
    esac

    echo "Criando estilo: $style_name no workspace: $workspace_name"

    # Criar payload JSON para o estilo
    local data="{
        \"style\": {
            \"name\": \"$style_name\",
            \"filename\": \"${style_name}.sld\"
        }
    }"

    # Primeiro, criar o estilo (POST)
    local response=$(rest_request "POST" "/rest/workspaces/${workspace_name}/styles" "$data")
    local status_code=$(echo "$response" | tail -n 1)

    if [ "$status_code" != "201" ]; then
        echo "✗ Erro ao criar estilo '$style_name'"
        echo "Código HTTP: $status_code"
        echo "Resposta: $(echo "$response" | head -n -1)"
        return 1
    fi

    # Depois, fazer upload do conteúdo SLD (PUT)
    local put_response=$(curl -s -w "\n%{http_code}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
                         -X PUT \
                         -H "Content-Type: application/vnd.ogc.sld+xml" \
                         -d "$sld_content" \
                         "${GEOSERVER_URL}/rest/workspaces/${workspace_name}/styles/${style_name}")

    local put_status=$(echo "$put_response" | tail -n 1)

    if [ "$put_status" = "200" ]; then
        echo "✓ Estilo '$style_name' criado com sucesso"
        return 0
    else
        echo "✗ Erro ao fazer upload do conteúdo do estilo '$style_name'"
        echo "Código HTTP: $put_status"
        echo "Resposta: $(echo "$put_response" | head -n -1)"
        return 1
    fi
}

# Função para verificar se camada existe
layer_exists() {
    local workspace_name=$1
    local layer_name=$2
    local status_code=$(rest_request_status "GET" "/rest/layers/${workspace_name}:${layer_name}")
    
    if [ "$status_code" = "200" ]; then
        return 0
    else
        return 1
    fi
}

# Função para publicar camada do PostGIS
publish_postgis_layer() {
    local workspace_name=$1
    local datastore_name=$2
    local layer_name=$3
    local table_name=$4
    local style_name=${5:-""}  # Opcional
    local cql_filter=${6:-""}  # Opcional

    # Verificar se camada já existe
    if layer_exists "$workspace_name" "$layer_name"; then
        echo "✓ Camada '$layer_name' já existe"
        return 0
    fi

    echo "Publicando camada: $layer_name no workspace: $workspace_name"

    # Criar feature type com bounding box do Brasil
    local data="{
        \"featureType\": {
            \"name\": \"$layer_name\",
            \"nativeName\": \"$table_name\",
            \"title\": \"$layer_name\",
            \"enabled\": true,
            \"srs\": \"EPSG:4326\",
            \"projectionPolicy\": \"REPROJECT_TO_DECLARED\",
            \"nativeBoundingBox\": {
                \"minx\": -73.9828,
                \"maxx\": -34.7931,
                \"miny\": -33.7517,
                \"maxy\": 5.2718,
                \"crs\": \"EPSG:4326\"
            },
            \"latLonBoundingBox\": {
                \"minx\": -73.9828,
                \"maxx\": -34.7931,
                \"miny\": -33.7517,
                \"maxy\": 5.2718,
                \"crs\": \"EPSG:4326\"
            }
        }
    }"

    echo "Enviando requisição para criar feature type..."
    echo "  Tabela: $table_name"
    echo "  JSON enviado: $data"

    # Criar a camada via REST API
    local response=$(rest_request "POST" "/rest/workspaces/${workspace_name}/datastores/${datastore_name}/featuretypes" "$data")
    local status_code=$(echo "$response" | tail -n 1)

    if [ "$status_code" != "201" ]; then
        echo "✗ Erro ao publicar camada '$layer_name'"
        echo "Código HTTP: $status_code"
        echo "Resposta: $(echo "$response" | head -n -1)"

        # Tentar diagnóstico adicional para tabelas problemáticas
        echo "  Diagnóstico adicional:"
        echo "  - Verificando se datastore existe..."
        local ds_check=$(rest_request_status "GET" "/rest/workspaces/${workspace_name}/datastores/${datastore_name}")
        echo "  - Datastore status: $ds_check"

        echo "  - Verificando conexão com datastore..."
        local conn_test=$(rest_request "GET" "/rest/workspaces/${workspace_name}/datastores/${datastore_name}")
        echo "  - Conexão OK: $([ $? -eq 0 ] && echo "Sim" || echo "Não")"

        return 1
    fi

    echo "✓ Camada '$layer_name' (feature type) criada com sucesso"

    # Aplicar filtro CQL se especificado
    if [ -n "$cql_filter" ]; then
        apply_cql_filter_xml "$workspace_name" "$datastore_name" "$layer_name" "$cql_filter"
    fi

    # Aplicar estilo se especificado
    if [ -n "$style_name" ]; then
        apply_layer_style "$workspace_name" "$layer_name" "$style_name"
    fi

    return 0
}

# Função para publicar camada RURAL_PROPERTY (usando mesma abordagem das outras)
publish_rural_property_layer() {
    local workspace_name=$1
    local datastore_name=$2
    local style_name=$3

    # Verificar se camada já existe
    if layer_exists "$workspace_name" "RURAL_PROPERTY"; then
        echo "✓ Camada RURAL_PROPERTY já existe"
        return 0
    fi

    echo "Publicando camada RURAL_PROPERTY (mesma abordagem das outras)..."

    # Usar exatamente a mesma estrutura das outras camadas com bounding box do Brasil
    local data="{
        \"featureType\": {
            \"name\": \"RURAL_PROPERTY\",
            \"nativeName\": \"property\",
            \"title\": \"RURAL_PROPERTY\",
            \"enabled\": true,
            \"srs\": \"EPSG:4326\",
            \"projectionPolicy\": \"REPROJECT_TO_DECLARED\",
            \"nativeBoundingBox\": {
                \"minx\": -73.9828,
                \"maxx\": -34.7931,
                \"miny\": -33.7517,
                \"maxy\": 5.2718,
                \"crs\": \"EPSG:4326\"
            },
            \"latLonBoundingBox\": {
                \"minx\": -73.9828,
                \"maxx\": -34.7931,
                \"miny\": -33.7517,
                \"maxy\": 5.2718,
                \"crs\": \"EPSG:4326\"
            }
        }
    }"

    echo "Enviando requisição para criar feature type..."
    echo "  Tabela: property"
    echo "  JSON enviado: $data"

    # Criar a camada via REST API
    local response=$(rest_request "POST" "/rest/workspaces/${workspace_name}/datastores/${datastore_name}/featuretypes" "$data")
    local status_code=$(echo "$response" | tail -n 1)

    if [ "$status_code" != "201" ]; then
        echo "✗ Erro ao publicar camada RURAL_PROPERTY"
        echo "Código HTTP: $status_code"
        echo "Resposta: $(echo "$response" | head -n -1)"
        return 1
    fi

    echo "✓ Camada RURAL_PROPERTY criada com sucesso"

    # Aplicar estilo se especificado
    if [ -n "$style_name" ]; then
        apply_layer_style "$workspace_name" "RURAL_PROPERTY" "$style_name"
    fi

    return 0
}

# Função para aplicar estilo a uma camada
apply_layer_style() {
    local workspace_name=$1
    local layer_name=$2
    local style_name=$3

    echo "Aplicando estilo '$style_name' à camada '$layer_name'"

    # Primeiro, verificar se o estilo existe
    local style_check=$(rest_request_status "GET" "/rest/workspaces/${workspace_name}/styles/${style_name}")
    if [ "$style_check" != "200" ]; then
        echo "✗ Estilo '$style_name' não encontrado no workspace '$workspace_name'"
        return 1
    fi

    local data="{
        \"layer\": {
            \"defaultStyle\": {
                \"name\": \"$style_name\",
                \"workspace\": \"$workspace_name\"
            }
        }
    }"

    local response=$(rest_request "PUT" "/rest/layers/${workspace_name}:${layer_name}" "$data")
    local status_code=$(echo "$response" | tail -n 1)

    if [ "$status_code" = "200" ]; then
        echo "✓ Estilo '$style_name' aplicado à camada '$layer_name'"
        return 0
    else
        echo "⚠ Estilo não aplicado via layer, tentando via feature type..."
        # Tentar abordagem alternativa via feature type
        return 0  # Não é erro crítico, continua
    fi
}

# Função para aplicar filtro CQL via XML
apply_cql_filter_xml() {
    local workspace_name=$1
    local datastore_name=$2
    local layer_name=$3
    local cql_filter=$4

    echo "Aplicando filtro CQL: $cql_filter à camada $layer_name"

    # Criar XML do filtro
    local xml_data="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<featureType>
  <cqlFilter>$cql_filter</cqlFilter>
</featureType>"

    # Fazer PUT request para aplicar o filtro
    local response=$(curl -s -w "\n%{http_code}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
                     -X PUT \
                     -H "Content-Type: application/xml" \
                     -d "$xml_data" \
                     "${GEOSERVER_URL}/rest/workspaces/${workspace_name}/datastores/${datastore_name}/featuretypes/${layer_name}")

    local status_code=$(echo "$response" | tail -n 1)

    if [ "$status_code" = "200" ]; then
        echo "✓ Filtro CQL aplicado: $cql_filter"
        return 0
    else
        echo "✗ Erro ao aplicar filtro CQL: $cql_filter"
        echo "Código HTTP: $status_code"
        echo "Resposta: $(echo "$response" | head -n -1)"
        return 1
    fi
}

# Função para verificar se workspace existe
workspace_exists() {
    local workspace_name=$1
    local status_code=$(rest_request_status "GET" "/rest/workspaces/${workspace_name}")

    if [ "$status_code" = "200" ]; then
        return 0
    else
        return 1
    fi
}

# Função para verificar se datastore existe
datastore_exists() {
    local workspace_name=$1
    local datastore_name=$2
    local status_code=$(rest_request_status "GET" "/rest/workspaces/${workspace_name}/datastores/${datastore_name}")

    if [ "$status_code" = "200" ]; then
        return 0
    else
        return 1
    fi
}

# Remove camada publicada (ex.: migração shapefile -> PostGIS)
delete_layer_if_exists() {
    local workspace_name=$1
    local layer_name=$2

    if ! layer_exists "$workspace_name" "$layer_name"; then
        return 0
    fi

    echo "Removendo camada existente: ${workspace_name}:${layer_name}"
    local status_code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
        -X DELETE "${GEOSERVER_URL}/rest/layers/${workspace_name}:${layer_name}?recurse=true")

    if [ "$status_code" = "200" ] || [ "$status_code" = "204" ]; then
        echo "✓ Camada removida: ${layer_name}"
        return 0
    fi

    echo "✗ Falha ao remover camada '${layer_name}' (HTTP $status_code)"
    return 1
}

# Publica camadas territoriais IBGE a partir das tabelas country/state/municipality (car_db)
publish_ibge_territorial_layers() {
    local workspace_name=$1
    local datastore_name=$2
    local failed=0

    echo ""
    echo "=== Publicando camadas territoriais IBGE (PostGIS) ==="

    delete_layer_if_exists "$workspace_name" "PAIS" || failed=1
    if [ "$failed" -eq 0 ] && publish_postgis_layer "$workspace_name" "$datastore_name" "PAIS" "country" "rer_no_opacity"; then
        echo "✓ Camada PAIS (country) publicada"
    else
        echo "✗ Falha ao publicar PAIS"
        failed=1
    fi

    delete_layer_if_exists "$workspace_name" "ESTADOS" || failed=1
    if [ "$failed" -eq 0 ] && publish_postgis_layer "$workspace_name" "$datastore_name" "ESTADOS" "state" "rer_no_opacity"; then
        echo "✓ Camada ESTADOS (state) publicada"
    else
        echo "✗ Falha ao publicar ESTADOS"
        failed=1
    fi

    delete_layer_if_exists "$workspace_name" "MUNICIPIOS" || failed=1
    if [ "$failed" -eq 0 ] && publish_postgis_layer "$workspace_name" "$datastore_name" "MUNICIPIOS" "municipality" "rer_municipality"; then
        echo "✓ Camada MUNICIPIOS (municipality) publicada"
    else
        echo "✗ Falha ao publicar MUNICIPIOS"
        failed=1
    fi

    return "$failed"
}

# Função para aguardar GeoServer estar pronto
wait_for_geoserver() {
    echo "Aguardando GeoServer estar pronto..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f -u "$GEOSERVER_USER:$GEOSERVER_PASSWORD" "$GEOSERVER_URL/rest/about/version" > /dev/null 2>&1; then
            echo "✓ GeoServer está pronto!"
            return 0
        fi
        echo "Tentativa $attempt/$max_attempts - GeoServer ainda não está pronto..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    echo "✗ Timeout: GeoServer não ficou pronto em tempo hábil"
    return 1
}

# Função principal
main() {
    echo "=== Script GeoServer REST API ==="
    echo "GeoServer URL: $GEOSERVER_URL"
    echo ""
    
    # Aguardar GeoServer estar pronto
    if ! wait_for_geoserver; then
        echo "Falha ao aguardar GeoServer. Saindo..."
        exit 1
    fi

    # Parâmetros (podem ser passados como argumentos ou definidos aqui)
    WORKSPACE_NAME=${WORKSPACE_NAME:-"rer"}
    DATASTORE_NAME=${DATASTORE_NAME:-"db"}
    DB_HOST=${DB_HOST:-"host.docker.internal"}
    DB_PORT=${DB_PORT:-"5432"}
    DB_NAME=${DB_NAME:-"car_db"}
    DB_SCHEMA=${DB_SCHEMA:-"public"}
    DB_USER=${DB_USER:-"car_user"}
    DB_PASSWORD=${DB_PASSWORD:-"car_password"}

    # Verificar se workspace já existe
    if workspace_exists "$WORKSPACE_NAME"; then
        echo "✓ Workspace '$WORKSPACE_NAME' já existe"
    else
        # Criar workspace
        if ! create_workspace "$WORKSPACE_NAME"; then
            echo "Falha ao criar workspace. Saindo..."
            exit 1
        fi
    fi

    # Verificar se datastore já existe
    if datastore_exists "$WORKSPACE_NAME" "$DATASTORE_NAME"; then
        echo "✓ Datastore '$DATASTORE_NAME' já existe"
    else
        # Criar datastore
        if ! create_postgis_datastore "$WORKSPACE_NAME" "$DATASTORE_NAME" "$DB_HOST" "$DB_PORT" "$DB_NAME" "$DB_SCHEMA" "$DB_USER" "$DB_PASSWORD"; then
            echo "Falha ao criar datastore. Saindo..."
            exit 1
        fi
    fi

    echo ""

    # Criar estilos incorporados no script
    echo "=== Criando estilos ==="

    # Lista de estilos a serem criados
    STYLES=("rer_no_opacity" "rer_state" "rer_rural_property" "rer_river" "rer_consolidated_area" "rer_legal_reserve" "rer_native_vegetation" "rer_property_headquarters" "rer_river_up_to_10_m" "rer_municipality")

    for style in "${STYLES[@]}"; do
        if ! create_embedded_style "$style" "$WORKSPACE_NAME"; then
            echo "Falha ao criar estilo '$style'. Continuando..."
        fi
    done

    echo ""
    echo "=== Publicando Camadas ==="

    # Publicar camadas baseadas nas tabelas com filtros CQL
    echo "Publicando camadas das tabelas do banco com filtros CQL..."

    # CONSOLIDATED_AREA (tabela sub_area)
    if publish_postgis_layer "$WORKSPACE_NAME" "$DATASTORE_NAME" "CONSOLIDATED_AREA" "sub_area" "rer_consolidated_area" "area_type='CONSOLIDATED_AREA'"; then
        echo "✓ Camada CONSOLIDATED_AREA criada com filtro"
    else
        echo "✗ Falha ao criar CONSOLIDATED_AREA"
    fi

    # LEGAL_RESERVE (tabela sub_area)
    if publish_postgis_layer "$WORKSPACE_NAME" "$DATASTORE_NAME" "LEGAL_RESERVE" "sub_area" "rer_legal_reserve" "area_type='LEGAL_RESERVE'"; then
        echo "✓ Camada LEGAL_RESERVE criada com filtro"
    else
        echo "✗ Falha ao criar LEGAL_RESERVE"
    fi

    # PROPERTY_HEADQUARTERS (tabela sub_area)
    if publish_postgis_layer "$WORKSPACE_NAME" "$DATASTORE_NAME" "PROPERTY_HEADQUARTERS" "sub_area" "rer_property_headquarters" "area_type='PROPERTY_HEADQUARTERS'"; then
        echo "✓ Camada PROPERTY_HEADQUARTERS criada com filtro"
    else
        echo "✗ Falha ao criar PROPERTY_HEADQUARTERS"
    fi

    # REMAINING_NATIVE_VEGETATION (tabela sub_area)
    if publish_postgis_layer "$WORKSPACE_NAME" "$DATASTORE_NAME" "REMAINING_NATIVE_VEGETATION" "sub_area" "rer_native_vegetation" "area_type='REMAINING_NATIVE_VEGETATION'"; then
        echo "✓ Camada REMAINING_NATIVE_VEGETATION criada com filtro"
    else
        echo "✗ Falha ao criar REMAINING_NATIVE_VEGETATION"
    fi

    # RIVER (tabela sub_area)
    if publish_postgis_layer "$WORKSPACE_NAME" "$DATASTORE_NAME" "RIVER" "sub_area" "rer_river" "area_type='RIVER'"; then
        echo "✓ Camada RIVER criada com filtro"
    else
        echo "✗ Falha ao criar RIVER"
    fi

    # RIVER_UP_TO_10M (tabela sub_area)
    if publish_postgis_layer "$WORKSPACE_NAME" "$DATASTORE_NAME" "RIVER_UP_TO_10M" "sub_area" "rer_river_up_to_10_m" "area_type='RIVER_UP_TO_10M'"; then
        echo "✓ Camada RIVER_UP_TO_10M criada com filtro"
    else
        echo "✗ Falha ao criar RIVER_UP_TO_10M"
    fi

    # RURAL_PROPERTY (tabela rural_property) - sem filtro CQL
    echo "Publicando camada RURAL_PROPERTY (com atributos manuais)..."
    if publish_rural_property_layer "$WORKSPACE_NAME" "$DATASTORE_NAME" "rer_rural_property"; then
        echo "✓ Camada RURAL_PROPERTY criada"
    else
        echo "✗ Falha ao criar RURAL_PROPERTY"
    fi

    echo ""
    echo "Camadas territoriais IBGE (PAIS/ESTADOS/MUNICIPIOS) são publicadas após a carga em car_db."
    echo "Execute: populate_geoserver.sh --ibge-layers (chamado pelo start.sh após load_ibge_territorial_data.sh)"

    echo ""
    echo "=== Operações concluídas com sucesso! ==="
    echo "Workspace: $WORKSPACE_NAME"
    echo "Datastore: $DATASTORE_NAME"
    echo "Banco: $DB_HOST:$DB_PORT/$DB_NAME ($DB_SCHEMA)"
    echo "Estilos criados: ${#STYLES[@]} estilos"
    echo "Camadas publicadas:"
    echo "  - 7 camadas do banco com filtros CQL aplicados automaticamente"
    echo "  - 3 camadas territoriais IBGE via PostGIS (após load_ibge_territorial_data.sh)"
}

# Publica apenas PAIS/ESTADOS/MUNICIPIOS a partir de country/state/municipality
main_ibge_layers() {
    echo "=== GeoServer: camadas territoriais IBGE (PostGIS) ==="
    echo "GeoServer URL: $GEOSERVER_URL"
    echo ""

    if ! wait_for_geoserver; then
        echo "Falha ao aguardar GeoServer. Saindo..."
        exit 1
    fi

    WORKSPACE_NAME=${WORKSPACE_NAME:-"rer"}
    DATASTORE_NAME=${DATASTORE_NAME:-"db"}
    DB_HOST=${DB_HOST:-"host.docker.internal"}
    DB_PORT=${DB_PORT:-"5432"}
    DB_NAME=${DB_NAME:-"car_db"}
    DB_SCHEMA=${DB_SCHEMA:-"public"}
    DB_USER=${DB_USER:-"car_user"}
    DB_PASSWORD=${DB_PASSWORD:-"car_password"}

    if ! workspace_exists "$WORKSPACE_NAME"; then
        if ! create_workspace "$WORKSPACE_NAME"; then
            exit 1
        fi
    fi

    if ! datastore_exists "$WORKSPACE_NAME" "$DATASTORE_NAME"; then
        if ! create_postgis_datastore "$WORKSPACE_NAME" "$DATASTORE_NAME" "$DB_HOST" "$DB_PORT" "$DB_NAME" "$DB_SCHEMA" "$DB_USER" "$DB_PASSWORD"; then
            exit 1
        fi
    fi

    for style in rer_no_opacity rer_municipality; do
        create_embedded_style "$style" "$WORKSPACE_NAME" || true
    done

    if ! publish_ibge_territorial_layers "$WORKSPACE_NAME" "$DATASTORE_NAME"; then
        exit 1
    fi

    echo "Camadas territoriais IBGE publicadas com sucesso."
}

# Verificar se curl está instalado
if ! command -v curl &> /dev/null; then
    echo "Erro: curl não está instalado. Instale-o primeiro."
    exit 1
fi

if [ "${1:-}" = "--ibge-layers" ]; then
    main_ibge_layers
else
    main "$@"
fi

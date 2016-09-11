module Swagger.Decode exposing (..)

import Dict exposing (Dict)
import Json.Encode
import Json.Decode exposing (Decoder, string, int, float, bool, dict, list, map, customDecoder, value, decodeValue, oneOf)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)


type alias Swagger =
    { definitions : Definitions
    }


type alias Definitions =
    Dict String Definition


type alias Definition =
    { type' : Maybe String
    , required : List String
    , properties : Maybe Properties
    , items : Maybe Property
    , ref' : Maybe String
    , enum : Maybe (List String)
    , default : Maybe String
    }


type alias Properties =
    Dict String Property


type Property
    = Property Definition


decodeSwagger : Decoder Swagger
decodeSwagger =
    decode Swagger
        |> required "definitions" decodeDefinitions


decodeDefinitions : Decoder Definitions
decodeDefinitions =
    dict decodeDefinition


decodeDefinition : Decoder Definition
decodeDefinition =
    lazy
        (\_ ->
            decode Definition
                |> maybe "type" string
                |> optional "required" (list string) []
                |> maybe "properties" decodeProperties
                |> maybe "items" (decodeDefinition |> map Property)
                |> maybe "$ref" string
                |> maybe "enum" (list string)
                |> maybe "default" decodeAlwaysString
         -- TODO Support other enums than string?
        )


decodeProperties : Decoder Properties
decodeProperties =
    dict decodeProperty


decodeProperty : Decoder Property
decodeProperty =
    lazy (\_ -> decodeDefinition) |> map Property



-- helpers


decodeAlwaysString : Decoder String
decodeAlwaysString =
    oneOf
        [ string |> map toString
        , int |> map toString
        , float |> map toString
        , bool |> map toString
        ]


lazy : (() -> Decoder a) -> Decoder a
lazy thunk =
    customDecoder value
        (\js -> decodeValue (thunk ()) js)


maybe : String -> Decoder a -> Decoder (Maybe a -> b) -> Decoder b
maybe name decoder =
    optional name (map Just decoder) Nothing

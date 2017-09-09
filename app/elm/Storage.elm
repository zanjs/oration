module Storage exposing
  (saveUserState, loadUserState, userStateLoaded,injectChanges)

import Json.Encode as J exposing (object)
import Json.Decode as D exposing (int, string, float, list, Decoder)
import Json.Decode.Pipeline exposing (decode, required)
import Interop exposing (storeObject, retrieveObject, objectRetrieved)
import Msg exposing (Msg(OnUserStateLoaded))
import Models exposing (Model, Changes)

stateKey : String
stateKey = "userState"

loadUserState : Cmd msg
loadUserState = retrieveObject stateKey

userStateLoaded : Sub Msg
userStateLoaded =
  let
    getModel json = case (D.decodeValue modelDecoder json) of
      Ok m -> Just m
      Err _ -> Nothing
    retrieval (key, json) =
      OnUserStateLoaded (getModel json)
  in
    objectRetrieved retrieval

injectChanges : Model -> Maybe Changes -> Model
injectChanges model progress =
  case progress of
    Just p ->
      { model |
        name = p.name,
        email = p.email,
        url = p.url,
        preview = p.preview
      }
    Nothing ->
      model

saveUserState : Model -> Cmd msg
saveUserState model =
  let
      map m =
        {
          name = m.name,
          email = m.email,
          url = m.url,
          preview = m.preview
        }
  in
    storeObject (stateKey, encode <| map model)

encode : Changes -> J.Value
encode p =
  object [
    ("name", J.string p.name),
    ("email", J.string p.email),
    ("url", J.string p.url),
    ("preview", J.bool p.preview)
  ]

modelDecoder : Decoder Changes
modelDecoder =
  decode Changes
    |> required "name" string
    |> required "email" string
    |> required "url" string
    |> required "preview" D.bool



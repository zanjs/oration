module Storage exposing
  (saveUserState, loadUserState, userStateLoaded, injectChanges)

import Json.Encode as J exposing (object)
import Json.Decode as D exposing (string, bool, Decoder)
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
injectChanges model changes =
  case changes of
    Just c ->
      { model |
        name = c.name,
        email = c.email,
        url = c.url,
        preview = c.preview
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
encode c =
  object [
    ("name", J.string c.name),
    ("email", J.string c.email),
    ("url", J.string c.url),
    ("preview", J.bool c.preview)
  ]

modelDecoder : Decoder Changes
modelDecoder =
  decode Changes
    |> required "name" string
    |> required "email" string
    |> required "url" string
    |> required "preview" bool



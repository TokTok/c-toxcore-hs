{-# LANGUAGE NamedFieldPuns #-}
{-# OPTIONS_GHC -Wno-unused-imports #-}
module Network.Tox.CExport.CryptoCore where

import           Control.Applicative            ((<$>))
import qualified Data.ByteString                as BS
import           Data.Word                      (Word32, Word64)
import           Foreign.C.String               (CString)
import           Foreign.C.Types                (CInt (..))
import           Foreign.Marshal.Array          (copyArray)
import           System.Random                  (randomIO)

import qualified Crypto.Saltine.Class           as Sodium (decode, encode)
import qualified Network.Tox.Crypto.Box         as Box
import qualified Network.Tox.Crypto.CombinedKey as CombinedKey
import qualified Network.Tox.Crypto.Key         as Key
import qualified Network.Tox.Crypto.KeyPair     as KeyPair
import qualified Network.Tox.Crypto.Nonce       as Nonce


keyPairToTuple :: KeyPair.KeyPair -> (Key.SecretKey, Key.PublicKey)
keyPairToTuple KeyPair.KeyPair { KeyPair.secretKey, KeyPair.publicKey } =
  (secretKey, publicKey)

randomKey :: IO Key.CombinedKey
randomKey = uncurry CombinedKey.precompute . keyPairToTuple <$> KeyPair.newKeyPair


foreign export ccall new_symmetric_key :: CString -> IO ()

{-# ANN module "HLint: ignore Use camelCase" #-}
new_symmetric_key :: CString -> IO ()
new_symmetric_key target = do
  key <- Sodium.encode <$> randomKey
  BS.useAsCStringLen key . uncurry . copyArray $ target


foreign export ccall handle_request :: CString -> IO ()

handle_request :: CString -> IO ()
handle_request = error "handle_request"


foreign export ccall create_request :: CString -> IO ()

create_request :: CString -> IO ()
create_request = error "create_request"


foreign export ccall decrypt_data :: CString -> IO ()

decrypt_data :: CString -> IO ()
decrypt_data = error "decrypt_data"


foreign export ccall decrypt_data_symmetric :: CString -> CString -> CString -> Word32 -> CString -> IO Int

decrypt_data_symmetric :: CString -> CString -> CString -> Word32 -> CString -> IO Int
decrypt_data_symmetric cCk cNonce cEncrypted cLen cPlain = do
  Just ck <- Sodium.decode <$> BS.packCStringLen (cCk, 32)
  Just nonce <- Sodium.decode <$> BS.packCStringLen (cNonce, 24)
  Just encrypted <- Box.cipherText <$> BS.packCStringLen (cEncrypted, fromIntegral cLen)
  let plain = Box.unPlainText <$> Box.decrypt ck nonce encrypted
  case plain of
    Nothing -> return (-1)
    Just txt -> do
      BS.useAsCStringLen txt . uncurry . copyArray $ cPlain
      return $ fromIntegral $ BS.length txt


foreign export ccall encrypt_data :: CString -> IO ()

encrypt_data :: CString -> IO ()
encrypt_data = error "encrypt_data"


foreign export ccall encrypt_data_symmetric :: CString -> CString -> CString -> Word32 -> CString -> IO ()

encrypt_data_symmetric :: CString -> CString -> CString -> Word32 -> CString -> IO ()
encrypt_data_symmetric cCk cNonce cPlain cLen cEncrypted = do
  Just ck <- Sodium.decode <$> BS.packCStringLen (cCk, 32)
  Just nonce <- Sodium.decode <$> BS.packCStringLen (cNonce, 24)
  plain <- Box.PlainText <$> BS.packCStringLen (cPlain, fromIntegral cLen)
  let encrypted = Box.unCipherText $ Box.encrypt ck nonce plain
  BS.useAsCStringLen encrypted . uncurry . copyArray $ cEncrypted


foreign export ccall encrypt_precompute :: CString -> CString -> CString -> IO ()

encrypt_precompute :: CString -> CString -> CString -> IO ()
encrypt_precompute cPk cSk cCk = do
  bPk <- BS.packCStringLen (cPk, 32)
  bSk <- BS.packCStringLen (cSk, 32)
  let Just pk = Sodium.decode bPk
  let Just sk = Sodium.decode bSk
  let ck = Sodium.encode $ CombinedKey.precompute pk sk
  BS.useAsCStringLen ck . uncurry . copyArray $ cCk


foreign export ccall random_nonce :: CString -> IO ()

random_nonce :: CString -> IO ()
random_nonce target = do
  nonce <- Sodium.encode <$> Nonce.newNonce
  BS.useAsCStringLen nonce . uncurry . copyArray $ target


foreign export ccall random_u32 :: IO Word32

random_u32 :: IO Word32
random_u32 = randomIO


foreign export ccall random_u64 :: IO Word64

random_u64 :: IO Word64
random_u64 = randomIO


foreign export ccall increment_nonce :: CString -> IO ()

increment_nonce :: CString -> IO ()
increment_nonce = error "increment_nonce"


foreign export ccall increment_nonce_number :: CString -> Word32 -> IO ()

increment_nonce_number :: CString -> Word32 -> IO ()
increment_nonce_number = error "increment_nonce_number"


foreign export ccall public_key_valid :: CString -> IO ()

public_key_valid :: CString -> IO ()
public_key_valid = error "public_key_valid"


foreign export ccall public_key_cmp :: CString -> CString -> IO CInt

public_key_cmp :: CString -> CString -> IO CInt
public_key_cmp k1 k2 = do
  pk1 <- (Sodium.decode <$> BS.packCStringLen (k1, 32)) :: IO (Maybe Key.PublicKey)
  pk2 <- (Sodium.decode <$> BS.packCStringLen (k2, 32)) :: IO (Maybe Key.PublicKey)
  if pk1 == pk2
    then return 0
    else return (-1)


foreign export ccall new_nonce :: CString -> IO ()

new_nonce :: CString -> IO ()
new_nonce target = do
  nonce <- Sodium.encode <$> Nonce.newNonce
  BS.useAsCStringLen nonce . uncurry . copyArray $ target

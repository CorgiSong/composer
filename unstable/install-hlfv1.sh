ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.15.2
docker tag hyperledger/composer-playground:0.15.2 hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� hZ �=�r��r�=��)'�T��d�fa��^�$ �(��o-�o�%��;�$D�q!E):�O8U���F�!���@^33 I��Dɔh{ͮ�H��t�\z�{�PM����b�;��B���j����pb1�|F�����G|T�$��s���cB<�p���FpmZ <r,�����f���E����&X��FVWS���0 �c�����/Á����l��a.��ڰ�Ӛ��t�6���E혖c{$��n��$��9=�j�\ա�;":s�e@}Pl\��>.���K�:�Y�RQ7D:��Ƚ� :�K��?����N�E^�=ҽK2�r������j��,�
��yy�����^h�Q��qQ����"����fDj�n2��Z
��S���C�,2���I���_-�2o�w�,xƂ����E��&T���r��`���'��I������X���S�_�t�B���5#����&�;뿀]����X���S���v�ç�i���#^���c��X�c� .�p� �g7{u0��$��$"(\�'�Tي�u?g�d�2M��cҲ�m
Ϥ]>́�i�	�f�����:�E�t|�K��Sw,�$�|�1�>N���A��9	�C��$��IJ�q:�f$�s�n-�����=*�4u;L��◔t��iъ*��Kx�隂���4QHs^V�{���8�'R��@ʚn*-�	5c�b��K�&�����F�Gխ������4�.�i�]�B!�Q�t��`���ƣJ��N�2Td(
�$��ҟ��D�HCRC�s���â_�A�_?'1�3(�K��\��!ܰ�#�z����ΰ��;i�q��r�_�?�	 V���B&!�4�Z��h��Bm��p"�k��
�̰�혝�Ϙ�9�V��t��B�1Z�!���-�� ˂w/I�Hi�����m��^����D����������Rf�f.�3�A�µ�K����ak�%Bu����bv؀f���)��z����B��`$����x���+w���8 �G ��cRiO�u�P����S�2�Vu2F��3֧ʃ؝A���i���G���cs��$w�c��A�}rQL��j-DdWM���4qCy8�A9�����HG�zMMi�Z6�%`﫽��N�#���X����m�f�3�'�7�f�n�	��;N/�މa�Jq�s- &<����v�[/^�'8��yq� �3��ӑF5�\��V�����to{����b�����r���)�?��{�1C�yQ�M�?�-������x֙��@�h�Xz��L�e���m��g���E�I?��gҹ��G�&Le'W~_N�r��_�Ԅ�b��oؕ|�`m�"�|�FD��r��Y9Yʥ�fJ��~�����j�m�1���5l�c�vۄAS�wy㟑�%0^`����n��ib��X[���G媼�\������j�z��Ц��K੍pg���+U+��K^�Yh���?��B�w�W�H���X��x��`�B��;0�H�my�����-q�]C^�(��V)�IY�&3*:٠c~��A���%�g8-�N��"�+Zî=�xr�I��Yf�B���	[�������WM���_�l��Éh��:x��y*�[ft�0/�9 |o���Ϣ�W��S�?h9�� ���(�M����E���?��c;'F�4w���P�u�rLx(���/�ιa��OL��{�w������E����.�\�`��?�2�Ǣ"��xn������<�f��p����Ɩ��B`��7C�p��N�e; Y�i����� �nCC��q�C�KV{䐳.�B��b�Rjg�W�.����7o�?z��-7]���Q�W�.�ɱ���ڀa�)#߈^d�B����Q��V$�'R��H��s+d""�7p���
�I����'V��:�s$<Jµ0=!Ʀ��|e��'�-��VՠnG~
0��E��"0v�����g�d6�Ν1�16�͇�6��;h����-�m��y.��Z���d�w4������ ��e��̚��\?Dāo.�4|t�Y9>��03"��q���� dm� ć��8_�w�V�ѽK�¾�%2]���Ɗ������y.�������(HK�o!0[�}U��>o��	6S�����p/ϬL8�xn �s#?�$�"9>kb�Ge��è����0;�7 {-ʆ����tU�����GQ�kޓ������ �@�]��k�lZVT��թ��6��&f���5���~����D1Ȧj{���O�Hs�>�Z�g�`]c�D<9��ܬ	�h���醳1I*	�k��XkL@6L�	0|B�w�����|�0���3��g�Kq�b���*a������u}<�,џG��.�0@୎��P��i��f��8\R�w>�x����eDv}$�æ�����;:"�6{��"KŘ0~ �0��B\�"UK{�5��6,��X�n(e���k��!��X�ܫ;����t�`Р�/�]Bb�6H�1�v'�&�����a�hmd�Ήrs��~f��R�P�d��f���xVx��w�84u�!m�iBC;�4,22���&]i~�����*ۤ��!�q(��9%��6�	TW�چ��("�J*䔨�)�߈�D��C���(���-&�)U"��5�+�!�Hf���4(`4	���x!��_���@��َ�U����)��:��zu�k.�# ���F���P�f�-���;D�F�gB�0�eB2�M�f����KO�z� �i�z�RJxY�s52|�He��}�|�~�m��y�Bg��8�%Rt��->����lR۲�5���zp��c��.S6���|�S�����
�y�+6��b\X��Z̫���e7<��T���p����S� �[�G������A��f�-,.�����(�) A��-D�,,trU~ծ�~����u�V��%���׸Kt�+F1��X�c�C���V�?F�7"��Y�u7��.v`�����:�z��p��.�������2�cp��Mb��v�f� |��_8)>y�'I�e��B���o��̻����������5���O��h�SDQHl�^����ꢲ�H�굄 
q�D�11QKDE�	)��k�I�mH��|���[f�����/��ɝ�Nv��!�¬|��Y�V}��0)ӰM�����W��Y�`����뛕�|3N�߿���e~O�t�^���~��~�W���q����Ϋe����c���Ä N	�h� ��0������쟺�=���S�N<�>�G��������ކǌ�_�����-��E���c��e׉���8m�i�����E�S�uֱ��A��_,�E�����2��ÙLe7/Xr���u|�>F����І�.��!$&"��l�
��O䲹�\��ԷF>�Km��R��jȽ\Rn�Jr��7��j$��7_�53�ҋ�T�8�k���O���)�=LAnm�|5�l�S����̹\J6
��T%�*4k�z�}�£�Y�T�zyJ%}����[Cig�cA??6ζ+�kìd����{�٬�N�'e�&pg;iz8�JF(4�{������R�W�^�4'�+9n���H�)M�io���d-_�{��q��X���^V�3�<n8R�T2�[�6<:�*m�s\��E��g��[�*d�\�|$��ׅ��y��OrC����G%I2n#_�t��u��3}�]��*�ܒ��v��a��r#��J��{�����mwc�,Y�[g�J��������ݣSɉ�q;�*��;�^��0����c�+�f�Z�4)?��tz�B9����A)v"f�ۍ��i�����"�,���e��^���N#-�I[��I����Oe9��I��\��ʧv�\�m�@7��%o������?t�Xrp��R�X^^I;x��y���`J�r>SM�)��-���L�C�r��x�����q�<��I�lU{��nJ�4r���3ۅW}�̚���z�D�-�5^�w ��Sb"�UՒ��֠C>SHOQ���2	G~�3�ƞf�h�	��t����k�4fp<�����@��`��Lӹ	oV�
���;w�ȣ?uݗ������G'��<���[�$?t�f�i�c&����k�|����z��P�b��r���䮩EZ�{̜�ˇ\��
�G��ճi���v���6�ɕ���M��j���W[�Y��???�)�|^C�ǌxت��%�/eu$Uw�m��jU�t+��"G�U���ީp������O=f�+�Պ}�V�|`^�/L��<f�?/
���HH�R� 7�I̼n3�����$1��H̼.3����� 1��G̼�3�w���1�|#�Z����|��x������"���n�SW}	�>�O���-������^.t���^�w���u)�8���rQIr�{V&���J�U���Fl�jt�A;��1��'�|+��t��=̖MӔ������:w�m�=~��zg\b�c4*9��[[AnR�O�j���܊	��-�=C�cW�K���O@���-�K��/����I�A	�q���'$�� �:���&���5dm���o0F�`j���o5l�@�5C��f�D���e�64`�\���V�a���)R@�R��%N���v��G H�m�� _K��7�Ȗ;H��XF�^�"�jH7{4�L5��Z�S$e�2��v�w��c��򠾷�$��A��@����Ao�����=|�~� �,�=
�Iu<|�2`M���H���`	!�N�3���Z>=o�v-:�� �1�7UA�<���0e��
����i�G��C�M  -�	C���r,٘v���>�m�{��� /���ۓ	��i	}p5�^<�&�~�V��������� �n3�����}:e@���,P^1ǯ��>lA�<���+�C��@ʦ
�~�>ip��κ�;�8�ͱ�؋���a��ɗ��D�w��ȵ6��m�.� }�.��yH�<$�JX�|���Bv��.���ځ�v��릉Ӵ��)z�8�;^U�=�q�8����qй��U�<F�b���{�G��ff���v�·�]L��vf��O�-m�3m���o�\6�R���r��r����A�!��H���� n �!�����
����!n�""?N�\���i*FS]���~��*r#.ɠ��.�������1��o�� ��r�~�6Ic�Sx�=���Z�DĆ�h��s�D�'�4��,���5?���=�yW}���!��[���Юk̀�[����s{�$a�T���x�ݠ�b�j�j��-���>8�!��l�udM�t�x,�|��7H�j�y#r;�1C810��h���� ���3P��8�kq�r><��{��`뒮O5��F����m�� %0�
l�5Bx��e�r/rC�#n𸸷l���D�p���T��&���ș���_y�LJ�hrs�ԶQl����ρ���P��%E����1�ƒ�"
;���nMo�Gh�[t�&���?tm$��1������D*�o���$q���V��A<Y�,��?���o�K�/ߝ�u�o�d�����ϧ��������k��	������o�{���r�'�ȫ��r1i�}/�Nf��&�R*�f��H��TFV�DNKSi\&R9*��HJ��*A�T_��H5	~�H9� ��w~�>}��g~����~�ɟ-�ڧԏ���$�{8�}<�;x���^]���c�f��o�z`��7b?z��o<����ׄV=���c�ݏ��}�g}���߿�h�k���F�5x�-˵A6��s�r��Q�I�eX�������Vo4X��Y��c�w���1�;�	��U��wƜ"0�w���.�Ͱ�i����&���B8iP�IOyK/��aBIX�Wtٻ\y(
M�弡�;a��Ť7�-�9�]�@�o%�%D0�����:Q��\h݂�
p�_YTF��n�p�b{�%s��tݢ�ʰ���t[��W8�Ɔ�Hw6;�{�꠼dFj�t��$l�G9�xڝ��ʩ�6;1mSs�B���4K{C�
��E��s��l�AAj U�BwY��&^��C��׋#�΢+�2���1� ��]�E�E�pۥ������;�F����^��4csz�t��H�J�#�W�܁�J�����t���`r��6�`� d����rz�0�'ӕ8]p�E.kR�=��NO��I*o�
�]Tfz�/�J�JK�N��4��8K�'rZ�-���h"�5�B��n%.�;��RӝQɝQ�WϨ��:�r�D��W�O*]��K	��B���n~$�s�"��j7�����!�������Q��e��=�J�k�ʞ뉞�[`P�p�.��'~�@���zz6ƛ�Ly�\0de�GT����uĶr�4���uJ�P�U�&��2m�b���өB[J������GS��&�%��F�r���Y�O�g���<�K��ks���F�f�T�蓕K(�O��A��=W�T��<��،+��1JQ:��l�ͺ�q���%�t�Y��y�����Y-I�+��t�׮M�:��}V����h�M���,|������{/�ފ݋��}��^��w}�/���_�^�F�n�j5������}���&z
�LCY�ޏ�v�k�{A�����%�����9w,v����K���W-��o�ޢ��ފ��7��%W��|�����c?�����w������
�2UZ�|���k�m0u���r��QZ�+gd�$>o�_`�V ���6�+n�c,,�R���®�5@x�����\�Ǻ.����u�9���\��7��`PE鈴��/,xf-8�q�=~#i8�R�Y�Rf�Χ�{줮NX.]Ou�jnDTk#����=c��{��@I����)���:�^������hT(�?)ZD�ŎD��q�,��H,K݀#�`9]F�r�w���Q}�i�LK	!�pAe����I�V#���A��Ž��^&�HE�p�Œ�Z֠C���>�6�^-�,��mi�a��(�=��eRã� t��{4l�
�]�k��l�H��6H��^o>�t��r*����JL�|f0�Hx�[�M*�r�(7��ϷGaV�p�J��g�����<w��>���m����U�|�B�bRG��%����p�*;\VM��^湇'\% w���;�t���w����1g���D8�B���Չ��F�Pw�d�+u�[��Y���6��V�$���ўh�UaȦ0�Yќ���r�\�6�:=���a�W�ӭ�i�*p����z�2�)�y����XN�|��-Z�e�z����\7���Lgpz �t��c$�>��|�,��- ���� ���l]+��r�3��+�2�2�$��;�N{WZ4�" �S�b���K�e�2^����a'pR�7(+[^5�<�N�W��DU��d�$Bu>jL�GFf&9����pF+qe�v��i_�,
��hb�=��.&�u�`a�������c�0iBu>(Xt�{�@i���F�P9�O��٪sX�:0;#.7��p��m��!��^���$��'�dҹV����BT�f�m�Is���,�L�D��@���C�dڕ�x��c��+iD���<O��މF.v���P�8o(PrP1ZY��Se�!/f�v�H�uz>�R&Ii���;L�h'$�m-��Lɮ��Nc����2�b��tr�kָ��)�K�k��ط�� ��~=�ZTu+���x�:ɵ�|�J��+�}_mj�35�[�ؽ���_�~��jc{f�ˉ{=�
��m�VX�!�s��(����bo�^������S���O�a�oc��2��(/�����K�ڳ�G�7x�q(�����<^���M�R�D�<���^��1�iS� ������2�q>�~���ɯ�BW��)��{��7��<���8��N5���{����>E�ґG�s�"_Ȭ��^���K�']���9�����t���N����"Sw���n��J�w�sB����i��Gq���5�wx��-�rj##Y�k(
����dپu��@Iv|"M��� w����v]�&x�	�}���Gd�c�o؄(��E�=�Տv��������G�ֳ��7
l��جG�����'��fݬr���,�KZ[�9C�����щ���". wLM�뵧t������o�#�q1j	����!�G��%3�;Ƃ���� �)B� �O5TI� -z��bt�쁩�M���4v�H� �±I�8��3��x�"���x�w�����j|���|x�~u�͗<s��� ���Րm�Z�F,�<�xoI���'�]����s��Ootx�6|���c��5Ӛ #`m<7����ٰ߇��@�YȺ`�F�b��OZc=φ @�(�'kL�VĚ����C�+�a#��@��7C�Xa�#�t�b�D;Xh�؇$0*�2�^�=��� ��Sc��܏7- Q��kb�EՉ/�rB�r�D��%�FW�z���
���5���8�;�O� ������{�~�ADi~	= �Z��|���c����>��Zt����z.�5�-Zװ��_p��-�ނ̈`	94$m�l@�,���(�3��[�nAKJ���$��Zu��RY�ۙ��(�0
� ����ؖ�j�ۜ0�i�'YS�D��k��f���)��<������p�3�:-�5H�R��Y6�s�0����g��K<D6��R(yf�~^���v��^S£�y�#�cx��F��1���J�DD�P�Jq�Ep�g!�q�ބR��5v��io_�@�Q�hQB��k�ƆD�q����Ic4�j ��h�
����17i�C���hk��yd;l�Y:`���
�϶+�R0�z��Qy�65$K]wqݱ�k�7Z��e��]i_�a�V�&��޿8d�o
�:8@pzl<h5�﷈,������ ��m��z>���'�"���?#�N�#-3Sk��0�w����e�Bp$����L��jM��QDN����ƍ-gS7	��b��y������#ל"�8�W��.Z����-�	<���Jǀ2�����}��_gk�kM�>��Ԕ�;s�9v;�@����b��];Z��X���u����gC�]��%������J��w�����������1���xZɎ�K�D�����lx��4����y�FFz��%����;*���!ׄ�Ui bGg�w.�/�
|�
��w��k�����l�H$�J�$��II��L��$*�%�~:�W�O��>!I����HU���\ZJ���D�%�M{���a�-/���c��t ����O�?9�ɣv���ر �y0����@9INS�,�x*�gTI%H-��RN��t:��2x6�Ւ���BR�d6��2!�%LL�����G?'n��ꅷ��m�E�����U���UG�/����{'��A�]����w��b�W#�Z�� ��\�kҕ�J�X���U�g������Ui�mr��iW����-�%pb��>AG���M^���9�.T���:�>��]VF:<��ٟ`t�A@yvd�*<�IX'�[�\-aO��n8���p��Zmm�b��-��o܁�j�E�`�6�=�]&0���mu{�@�Hv���)�<�t5|�ךD�"_-�9�����{�D��|�]��h��vq��p�U�z���Ofcc��H$�;��\�&����[=����j�ƏF^xz-P�9����������j���j�/W9�Sk`tO2:�>��lt�t�ɳ�@��N���4;�z8��DZ�di�f��$o͔�\P>_k�K,���+� VW�}*�M=W���r�<�g��|җL[;����E��&Q���:D��M���tɇ�f��m7�o��5�E~Lv��	AW��6V�����Σ���ر[Z��.f7�m������H����q�YMlN��#�^?������Z0��{��_)
'���F����Fw�����I���n�o>=��?ã���I2��[��H_
��q��7~���6��ӿcڊt���w��m��5����������$�m�OeRw��6�m����+�/z�����E���_������J��@s����s�@�E��3�/��G��u���J�-�OSs��5<��3Y� �#E��OR��JJ.�%-�ų����2I9��j2�jD���c���󫝾��d�8��%���J���a��9�����][s�h׽�W|�V���[�rRA���W��(�
���_M:�3�3I�;@w��J�2�Q�z�^{��,Z�x���4q�cw����b�vu7��=��,���I�^nۨ���H��P���uȐ�牋��P�pN��go��W���Z�Vo�:D��a�t�1���i��[i�C���~��N�G���������lHݯ�U<����8�h������U��?����?=�������;���������o��u��������?���?��+A��i�6.Q� �����i����*�,���/L�V������?)�����U �ꄫ:��_z�����?�����J� �xP����?��k��w����A���5�	�?�����[	^���[�n����{�`�qN+Oz|7���S����e-���.�/���m����������{�����o��(:�7�ʈr~�����'�6	���2�^g-��zq3��h���{?�e^��Ru�]�%a.�=s2��>�,�m�d���vFs�Az齾�����|��g�˓=�)Q�ȕ�-��q{t�L)�d���ҟm׋�nO��ާt9���Y���S"=G�<��e+�;̡�()�����HR;�$ph�;M,'	�-'�v>c�������Vs�s��B7Ӡ�������iA,�z ��������׆f�?�DU�F���p���@��?A��?�[�?��*� ��������?��k�?6���4�h�?�!(�?M��a��>�:�o_��k�o�	�T�ra��f&�qR�7��������뿔��;_t��z���p�uvlK���Y��p�I����܏6����l�O����ņ�Z�WE5*p��en��N�5���Vg;bCW����{]
�P<����N��B�=��+Q25���G^��om�[�_82ե�Q1�-	D#y�>�zk�؆rng˵>c�A��Q�f	�0��$S/<J�☻>1���-�@6�\奋K��Xo����������p�U��o^�<=�P�� ��?��k���|���_	���󅏳������s��}��1���)��� ���dH�a�����&y��B��~4����C�_~f�V�]mu��t��Q�A�4�N��?�6�"OEw�֧���H_��M��[�5Z�|ey�.�h�E�qi�Af˾{XO�C�l��fKJ~v`�(��X���^�t��Ј�:�q;:�޼��oE����5��y]�Zф���������� ��w����u��M�����Ϭ�����GMi�����,�����g�?(�v庫���,=��J�d�X��h�z�%cz���u<�D�Ȣ��@��.��#le�qJegl�.I!vǖmM6Sd�pb*�Q���4�oE3��ߚЀ�?����{�+�	�_��U`���`������W���4B����#h�U�5��W�1_����w$���)�?˸+��]��|UK�)�_����Q�\���G� @���w  ճ� �Jՠ3N���P�"�K ^�@0O��9����yJje�%���=,�a���Z�P���ʲ�QG*��q�զ�2o����|� �޽�7��|�YEnP �k>�w���K���=�^�v���B���A���x���zÅ��hC�s����e~�b�A"��逴�A9Z�K���i.u�%��b�N���&$D�>���M��+��*c��]���^���L�q<[�j���b�S�l5���
y4�ҁ}�HFH�M�w�I��'\�EG'������ًM�8�@�Q����ǟ���E����v?�A��T�&������`��T�����XT��ߙ�O���U ��!���!����'��kB%��=��=��1��ع7ǉ�
0��<�a(>d1��B���� <� �Rl�{��b燡	����ߧ�����g�����.՝C�6K�&:���X�βQPKc?�J�ЩԤ�/��H���H^,��Vz�U;.v�w�S�!�)v�8L�,��fr3��P��*ft��C���A�)�m�i���[ф�����O%�x��E<��*��*��;���������������P�{�M�M�?���Ow���U���_�}�_h7U���濓8�U����[�7�����vl�.sT�\�)��:1�濃���oY�^��X"?2�}��#�߷V6��E11'�ܛ���N��"��~w��vM��>[�>N�'֘�3m��sF^"������z2f����y�����Ǵκ��+dΰX5����Rʥ�ʶž.P��˕���o϶�o�7�;��*��a�_�f��Xa�z���ڌ=�Ky��~*;tőTS�2�dI���=)�+yz£˭�be����)��I���Y�Ƥ�w���T�y�Z�<{���X�=,�HϞ�3=�]����j���	��?�߽����s�&�?����Z��o�P�?��f���0���0�������q�/O2� 	��?��k�C��>T��O_��4����K�P�W����_�����z����1�U����cv��u�N�cT���S��P�W�&�?�a��?	�_����c�p,���������5�?�C����������4��!�F �������_`��4��!�jT��ߛ�@A�C%������_z��������0�Q��`3�F@����_#����� ���X�M���?���P	 �� ������&��5��ϭ��������������?���P	 �� �����?���Y��]���s�F���g�����W�F�?��W�&��0�_`���a���.��������������!��@����_���� �?T�&�?�_Š��,�/���H�[p|�(�x� �+A0������X��q��x��h�������h���M�K�?��k��2{��;�k�)�[*v�»y�a�Z�����(�}q���iht&IrJ�r�#����H0$ANRf:�h�;��Il�S)I[~!�x�\�}��IH;�.щ#i9�:iz�DHx�����җ�6nBQ_������{Qu��C����5��y]�Zф���������� ��w����u��M�����Ϭ�����V>��vk�퐼�_�Rw5������l��s~v���R���:��Vb�(5h���T�qr���t�!�q�Qx��mu�:���F�r9۝;�~����$vhX`����v5\*���[ь����w�+B����#8������&���W}��/����/����_��h�:��w�c�����x���O��?���KǤ4��֚���ĉ�Y������l����n�N]���;�X"o��#w}���ڒOk~�PVw��#��S�\���X�f�`di'�ӏ&6ʨ��"mŬ���������#fG��h`{F�w���v���;}��{zt�m��t�b�����A���x��V����,0 <��F�04:��(�^�^(��H�8ĘHk���e����+��vٳ��yY_^ܟN}2��j1�9����:�V��v5!��tN�[��*>��Iޚ��F��n��=�F��������?���a�=��7�����8�+�G<�o/����O�<�JЄ�����w%����D7�j,�x�������U�	�O`�}�������s�'dz4U�������ԕ������-I���5�C7Ns����Q�y�?_z�~ׁ+|�g��e�z����o��i�yv���z�&�{���;œ凼�ޏ������}����֥��ыu9�Y�7��Z��5�db�_�VU���X��ޖ4�q�I�V�$�PA���L6
P:�z�H�����5-5"��e�p/xkf����q�I'/;dRr�S�p���\1���s��{���7o���M�����r�Z����<��}���Eu��31�#3%�u�3{O�Ds�-/�Gٶ0��	�tk�@> k�һ�7.sdtYT�X$����D<�z�韏8=O��S�<N�J:�S���;�'�y���_�"s��sT��������r2P~_��������+B5���i�gp����S��/� ��ߦ��_`���g���H~ᑬ�t��>�{!�s���(4��������0�W	~����D���Gu���!�;?���pפֿa��3CZ]̉�+�_�����_�
��rS+0��V|�����}G���X���@�Β����JP��?8F��U������A�U����~y�������s�����P�\�M��"���<�Z�/(�_ꔂ~��n�>�o���#����C���Mu�y��/�ߋ퇼��3�8���X��.{d$�גwð�2�R��6�7�1�`�?��6tcm0���� �u���RB�-&�t��E���o��^����C�~����X�(�E�%�[,�{�t/���"��V���l]
����ixY����f3�1;���z:��(F���m�N ����� �a�)/pt)n�%��-���O�U�BUO,�pQ������^��G<�����JP��O{L@!�q8F.8��u���͆���i�8��{��ښ���S89�Sgʓ��N͞*@@�~�LM� �P�S���m��N';�b��W�Ĉ"�<�y�Z�Jx�ň}��DФFt�Q*���I�������c�o�o�������ړ	�!�Z���c��81W����>^�Z��u�`T�����ۖĵ`?j[��ﵼ�������?�,B�_d���n������� ��_Kra��L���Z���:R��s�i�����W�?KB��
�������;��(�u�����R�ػy�������?�r��P�r�G��/�>V������i���ƕ�XlT&��B<6+�cs���S��U>=b�2r�����e�
{\�r�M��!��>Z�:��Jxa/�<���i1g$�ý����69����9�V:��3��B~9r:���e���n��Qw=-4�m;J�sK��X�M��M��fCn��2�����?
��j�q�/t"e�٣��Ao�N�Rl�z��+k�gG�m���ac$?�*C[���U��^��nG�smW3ƥ�)O��Z-���'�=v�b|�R����6����sgW�TI���R�:��r���P���R�	��zSRO�r��?M�qk�o���
i����V�����_��BG��A�G&�����l�S���O��	�?a���[���9���I ��o�����t���P.cd"������0��
P��A�7�������E�^��Y_#�����
��?2���U�w������մh2�?�?z��1��S��'���� ��G��$q5��J	��u!����\�����i�����HK����C��0�#������K&�~���?R�����@���/�_��� �?R"�!��D�U��¡�C:@��� �������K��A]�@���/����Ȉ�C]Dd"������0��
P��?@����v��F��I��/pl��������eB���`�W*dC�a�?*2���d�������L�?���D��K��߄��߷�˂�����H�L���a�z��њQ�H���V�4)��fV�D�&[2	�b���Z���L���Eg��[�ty���E�:������"�ow�a�j����U��ߐ��V�5�r�Y�Gb���HK�:�aNk�9u�xE?��	�KMF�[^�d�Z�t��7��=�j�.�W���j��Q��d��JAajk�E�XS0g*��LWS�ފ��NۖĐ!\^��ű�m=�.	�Q����%^�T�9޻:)�<cd������@���+��Yh�!�CG�������?�!Q_��%��:~f��kv��wR�M�
c�"���ʆ鏢�m�&-�݅�bgOz���&��Y��_�u��t�^���&
;,�`�_K�~�c�բQ�֬�L�x�^Cy9�.ԑ��ȥ�ۅ�h�|W���d��/B�/"P����`���E����_�������/����/������< B2��h�������7��=��ֳ�k5�З���h]+?td���/����O�χX�%~*���������6�eo�+��tG��Vow�jo3��ᬥ��<[���(?��Q~��5�N��W�-�F��5\���J�yE���*��v�۴X[�~�ਲ਼;;O�O�J	�T�٣�����d��-J|Ǩ<�)D�����^��`��D�D�����Z�������^x>%�|���NMg�ё���ʤF����<�ו	���0)���)R������b;N�QP�֐��݁a��!�Z�zиn��|/ɂ�#h�����n��^ �=2J�������E6����oO&�����ł��Aj����e�?h����Z��o�z���O���$��� w�?�?r�'n��@�O* ��������?�?r��n�������%��*�铖�_��X�)���P��?B���%������/��?X)�߷�˄����Ȍ���H�D��\�����
���8%��s�����~��m~tl�lw��,�*�C맛�aDR�)�#�s?��
��r���ɇa&�#I��^��;n��K�o��{���^���):a���O�Tew������6�E+3mj����k��Z�>��5ޞ:���p�Z7�����0���d�N㵤ڎ��$��Ѽ�K�/v#�W����Ṃ�pK��<ˆ���r�}8V&Ro3q�dy�j���_���e{,�D>X���7�,��ak�^��� 2�Z�׆�ZyxЩXDaλ�Z���ޭ���J������Η��a�	����@��^,��Z�#�߷�˄���?2����� U2�ߨ����*@�/�����������D �ϋ���w	�����2��4������W@�[�����#�[�����Q�Qݎ6��<���+��j��7ƃ_j�_������{��7�ݕ�/i
��=��S@il����Sm����ZI�hF�a7�:�z�^C�&Mr���b�
��7%�r�'Aw�(�Ґ�"��B�X��>d���%I & K� �(�qQ�S�Qm���E��
�����ܔW�f[v�����ns������tP^7��@��&���^S��0���&�[c�ӌ���ˇ�?L&�qc����
��ߧE�Q_������Y��"q��c�?���T�b��Z�Z����"�����4i�$^*�4aX���E��2f�Ē3������W&�k�O���?s��>;e{���d�'l(�>�ԈŰ���nK���9	�������q3&���7<_��nz������&/i%�{vQӚ��LeN%��/N��:Y<�F��4���sL ����a��ג����i��,���9Yh�!�CG&��� ��?-���/�]����?3��F��h�������U
KJ-���k�C�Iv&�������LO8��AKz�W�j��K�
BD�k#��cO�c�8d�*�/̎M��+�}O5Ö����B{�	��:Z���R$��%����/:����ۃ��74X !����_Ȁ�/����/�����(���!�������-�7J��-<����𘑻o[2�/F�`��WS�����)�g����.���/�`��D&�jZ'/8��W�(h�����˹d�M"�OelY(�i��������R��u��z��U��i��m��/O��<,�y��E�Γ���U�E���\��	2�H|����n%��@��_�5�T��p��%Q��oY�b�9��w�0���./�G�Q��f9�+á?7���i���/b_�I"�uq�m�j�lz�!�C�������Ǧշ6�b���:F	��_F9�ϙ=1ڋ�!���Zujwf�	�%��2��3�߭��Mn����=��׵�������g�ORL��O�ssn�n.�c�Zh�><5�=|��?�u��o�9�㻊�Q��m�_��}{T�ί��>x��rVfNx���VA�?&p�܇�.�v!����ç�����AO6�������+�7��z�x�S��d���]+��e��3ټAߘ����]J�[���}�7���|�{|�$�$�������t�-�Z0ǰ��ă�6n�r� ̙������|�s�j��1k͝X`���>~O�M#��FN�h�����k�j�XN��J�,����f�����o���7��(��޽�GΘ���o|���<׫~�]A�_��~���w���=�E��Q�W��Is�X0�{�|W�>X��}������5��*~[�����܇Yr��_Bk��G��W��6����Ʌ�����q-���:_� �c��w��vn+���r�3����}���>���+�5����+�O>�ݭu���4����z��X�2M�[�;k���zR��9��`9�4}�a����x�����s�y6����8��Z��'��`�Fa�|�
�F���'�n�k�_�'���Y|�cB�+~l�b�c��ZMI�۳��HrvA���e
�����^ua��~п<���                  ����=�� � 
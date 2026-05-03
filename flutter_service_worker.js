'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "71a4a4e879c6aca70e4889857b4c6c23",
".git/config": "bc1ef126e27c5ce523e3b5ccc3c92de5",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "e0b5b08e209fa15f48d796e8976bc42b",
".git/hooks/fsmonitor-watchman.sample": "5c90c1740b0cacecb469934e16fe8cb6",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "07c0893706351d2c7b4600320e9c1636",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "4085c8ace50e314b69497b4e7a24c3db",
".git/logs/refs/heads/gh-pages": "4085c8ace50e314b69497b4e7a24c3db",
".git/logs/refs/remotes/origin/gh-pages": "7033d743f5c27a29d58d87d0d671c6a0",
".git/objects/02/16f690c6d43a162474d67758cf905b604d99b1": "9d65a6ecf5affbbb4cc77d715ea218cf",
".git/objects/07/6d14360a90899089961561f4f9a3795b3001e4": "73edd7b67cb605c418045f640e9fe28c",
".git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
".git/objects/17/7923464c04b34cb276e8d562ab4b532c6de7ab": "8f4e75ab926efd0b4c5450bd21eb3b14",
".git/objects/1c/808ad6030891d3bfb446a9e7e7f9c08c700a54": "8b0c7b4ac488f257fbb3a8c1893abb91",
".git/objects/1e/26f858d613661a822ef534b8df9393eb8077b4": "decb13e24b1ec53a48749f9a9ec5a015",
".git/objects/31/d146fab25b91bf069696c06a95f2abadf66d19": "4066ceb6a34079ac15069534250eb336",
".git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
".git/objects/3d/a32cfdd002ffc496bc4bb7e6fe30c6802839a7": "7a9c28f0c34456fd86b7bae1fcd29686",
".git/objects/42/9cbddf7dbff89b6908a11f0da16d45e9eccfc0": "29a0b04386ee71cf389a30a4b5b8f5a7",
".git/objects/43/2c3ebea02dbf202395ee7cb975e30abcfaa2f2": "d4722caa4462c6397bc480ba7d45bbdd",
".git/objects/49/8621d31f4107b50d6fa7e7fc410e5a2f8227b6": "29816afbea07b935fdc736a5f05ccbbc",
".git/objects/4b/6de6a09968b75ec5d964bc9d55dc253a341bed": "1fb2405042279dd13e58c2176a775547",
".git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
".git/objects/51/90a0011ec14b7e947dffad667fd7436202d1f4": "714a6605fecaffe1adb7e05a8d2ea3bf",
".git/objects/53/11d402090e105566297f54ca0a2125f8a3dff4": "faba3a50ee23244a04b2468b6cfff281",
".git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
".git/objects/6c/256556b22f9f9a8679469ca732bc6ae083c411": "0097a49f2b92f57aec37e62b62535464",
".git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
".git/objects/70/de602ab17cf82066cadb18ede118741b258a6f": "4038e078a7c097d3ae323f0b940b1b75",
".git/objects/76/4552d04450cf9967337cb6c8495ec104a9fd53": "e002582f631d403213ca9fa819ad1a6c",
".git/objects/7c/1b8a7ad06519d3e61ddb1ef128dfce7df3b9d9": "e563308cb8fc50b0a0429c976876e91a",
".git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
".git/objects/84/c41f1bd6932cc39101a0338b584c8e669f8540": "ef521f82035d51c7763b9ecb2552d893",
".git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
".git/objects/87/8db59279368c6bb4e7391e8164673f2e92f75b": "92331e2a4e5ed5c3da940719a9aaa989",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8b/42a4f40fcc48958f0fb6ef8e3485186fbae02e": "9fa9c9281c1c4f4e7568f5f0e7bacba3",
".git/objects/8c/f5b9f76fd942f155b0d058f1e72f41d768aa9f": "c5ad9dc4e913ed66664808c20ef3c4e2",
".git/objects/8d/fbaa54258e69ed33b5ab6a66518e146338b372": "65394166b6784ece6f28d41c1ec3b3b2",
".git/objects/8e/21753cdb204192a414b235db41da6a8446c8b4": "1e467e19cabb5d3d38b8fe200c37479e",
".git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
".git/objects/9b/1e9d512a127510b3e50325badcc21f96385ef7": "8479fec7f2126b267d3b827f510c70a3",
".git/objects/a2/d814b01da029619177e76127df14d1bdce6323": "eed4064b42f9488808d841371d0d0a71",
".git/objects/a7/3f4b23dde68ce5a05ce4c658ccd690c7f707ec": "ee275830276a88bac752feff80ed6470",
".git/objects/a9/5bcc85a8760e48af398823c98b53bd2286d7fa": "8d04da8e33d4051977a3d6afc98be516",
".git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
".git/objects/b0/2c4cb241bf88c7fc7b43af2f34e0f651c864fa": "fc809cf11bd5827961049d2c0e448f51",
".git/objects/b1/1452d731000b01dd56f55587b1e5c22fb7f124": "35aa049dd41ed745cc64c56cdd588f7f",
".git/objects/b1/e0170dc0649b3ec3aee493a85fd2b949b6c1ee": "523c6fb203342249e1666bdd30d900a3",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
".git/objects/c3/332019584ea4ba588378ad35dae53ec9675174": "12ca294f3e043ed988a7b2ea7fda461c",
".git/objects/c5/d8a2da5ad0f41cc74ba035615b37c2e5e0e8a2": "240632b9bce8be3b5bc4b28998b6caa8",
".git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
".git/objects/cb/db0b42e2f9060341eb73ab7fef6770586f0e99": "dc80bff81f99cbed86c53713074ee17a",
".git/objects/d1/2323937e1a0e120f41576ebe26ae9508a50a45": "ab92b9ff85ee1fdd06b8c1c459cb021b",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d9/537b8a437202fabb6b86d3e4517bc7df7e21ee": "885b6aee5330fc19b58c40745402d3b1",
".git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
".git/objects/e0/580867aec39f5f15ee84636d406d910aef5966": "25f4999ff576a0029db4a488dd12d756",
".git/objects/e8/7556cc949eb5979ecb3b1ec8d7de6d9f13e2fa": "454c5c2f4b729e4d30ce94f895a1b891",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/ee/d56e364e24fe6d27dce035b009947d545a10b5": "e32cd9f36472b5b6d3aae2797a3543e5",
".git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
".git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
".git/objects/f8/4b4fbbb5d2a0059c9fa231b15a422f6b1f4350": "ca099a3692dbba597b502d46657b3405",
".git/objects/fa/cedc43df84de5e311c8788992797acd723a69f": "6ed6a4f38a1360f5878e2da8aec735ea",
".git/objects/fc/8c85d418b6fe4db7441d66f120e64ce04e95b6": "78fbdb4014ce8b476c9cd0c8f0bd524e",
".git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
".git/refs/heads/gh-pages": "7c8ebbdf30f46f761eeb531b0e308fa0",
".git/refs/remotes/origin/gh-pages": "7c8ebbdf30f46f761eeb531b0e308fa0",
"assets/AssetManifest.bin": "75eec839a142d2cbb41bb9cd5a267344",
"assets/AssetManifest.bin.json": "f26c1d930f5016333679164ef46ef23c",
"assets/FontManifest.json": "78edb7b94f3ec0f4faa82568e50d5066",
"assets/fonts/MaterialIcons-Regular.otf": "03d21144a426a87d1b0de497c5af0afc",
"assets/NOTICES": "0678e75d419a24f99fcf3ae11b422206",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor-Bold.ttf": "4f59e81563e413635c57d78338d33b92",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor-Duotone.ttf": "e0b028909550eda3023ac5765bf8c16a",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor-Fill.ttf": "612af00267f5e8a429531399700db66e",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor-Light.ttf": "6c53da4ecc310dd5dbcfafe3d916a346",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor-Thin.ttf": "9ca0acf8bc84ec2421f96f835017f321",
"assets/packages/phosphor_flutter/lib/fonts/Phosphor.ttf": "c2ecd49d10b76c3f9b9c072966cc0c3c",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "1cdf35f5e785317c0d8a43273b8f9689",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "736237c0924b2d2bbc236f177944f35e",
"/": "736237c0924b2d2bbc236f177944f35e",
"main.dart.js": "bab4d6ca86556f24b2435931470c0f83",
"manifest.json": "4f403e1d51bf6d539af8be8c9a9bb033",
"version.json": "7239d27134e551c8eb4151f04b935c0f"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}

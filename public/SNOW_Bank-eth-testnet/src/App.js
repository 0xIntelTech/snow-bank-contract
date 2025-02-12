/* eslint-disable react-hooks/exhaustive-deps */
import React from "react";
import "App.css";
import routes from "./router.js";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import Layouts from "layouts";
import SuspendLoading from "components/SuspendLoading.jsx";
import { Suspense } from "react";
import "@rainbow-me/rainbowkit/styles.css";
import "react-toastify/dist/ReactToastify.css";
import "react-tooltip/dist/react-tooltip.css";

function App() {
  return (
    <Suspense fallback={<SuspendLoading />}>
      <BrowserRouter>
        <Layouts>
          <Routes>
            {routes.map((item, key) => (
              <Route path={item.path} element={item.element} key={key} />
            ))}
          </Routes>
        </Layouts>
      </BrowserRouter>
    </Suspense>
  );
}

export default App;

import React from "react";

export default function Button({ label, onClick }) {
  return (
    <button
      onClick={onClick}
      className="custom_btn hover:bg-symbolHover transition ease-in-out text-black"
    >
      {label}
    </button>
  );
}

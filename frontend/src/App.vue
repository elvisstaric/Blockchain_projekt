<template>
  <div>
    <nav>
      <router-link to="/guest">Guest</router-link> |
      <router-link to="/owner">Owner</router-link>
    </nav>
    <router-view />
  </div>
</template>

<script>
export default {
  name: "App",
};
</script>
<style>
body {
  font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
  margin: 0;
  padding: 0;
  background-color: #f4f7fa;
  color: #333;
}

nav {
  background-color: #004aad;
  padding: 1em;
  text-align: center;
}

nav a {
  color: white;
  text-decoration: none;
  margin: 0 1em;
  font-weight: bold;
}

nav a.router-link-exact-active {
  text-decoration: underline;
}

h2 {
  margin-top: 1.5em;
  text-align: center;
  color: #004aad;
}

h3 {
  color: #0066cc;
  margin-bottom: 0.5em;
}

div {
  max-width: 700px;
  margin: auto;
  padding: 1.5em;
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.05);
  margin-top: 2em;
}

input,
select,
button {
  display: block;
  width: 100%;
  padding: 0.6em;
  margin: 0.6em 0;
  border: 1px solid #ccc;
  border-radius: 6px;
  box-sizing: border-box;
  font-size: 1em;
}

button {
  background-color: #007bff;
  color: white;
  border: none;
  cursor: pointer;
  transition: 0.3s;
}

button:hover {
  background-color: #0056b3;
}

button:disabled {
  background-color: #aaa;
  cursor: not-allowed;
}

ul {
  list-style: none;
  padding: 0;
}

li {
  background-color: #f9fbfc;
  padding: 1em;
  border-radius: 6px;
  box-shadow: 0 0 5px rgba(0, 0, 0, 0.05);
  margin-bottom: 1em;
}
</style>

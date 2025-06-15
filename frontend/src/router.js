import { createRouter, createWebHistory } from "vue-router";
import GuestContract from "@/components/guestContract.vue";
import OwnerContract from "@/components/ownerContract.vue";

const routes = [
  {
    path: "/guest",
    name: "Guest",
    component: GuestContract,
  },
  {
    path: "/owner",
    name: "Owner",
    component: OwnerContract,
  },
  {
    path: "/",
    redirect: "/guest",
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;

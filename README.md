## debrand

Convinces Minecraft it is unmodded.

This is most useful for QoL setups, where there is no need to change the brand of the game.

### Notes on hiding mods from servers

This mod is most useful against passive detections (since by default, the Minecraft client volunteers its brand to the server) and cursory glances (that don't notice modified behavior).

However, know that it does **not** protect against:

- **Behavioral observation:** If a mod allows you to take actions that a vanilla client would not, this is obvious and will be visible (such as to anticheat).

  **Examples:** Proximity chat; swing through grass; any changes to player movement or reach; etc. Note that not all of these can be detected with 100% accuracy, but they can raise suspicion or create evidence.

- **Active detection:** If the server probes for a specific behavior that differs with a mod installed, such as using the translated sign exploit in versions that had it, that difference will be detectable.

  **Examples:** Any mod whose translation keys are known; any mod that communicates with the server using custom packets; any mod that creates packets or responses that differ from vanilla; etc. Any of these will create certainty that your client is modded.

- **Chatty mods:** If you have mods installed that reveal their presence to the server, that will be detectable.

  **Examples:** Fabric API / Fabric Registry Sync; proximity chat / other mods that send data from the client; etc. Any of these will also create certainty that your client is modded.

- **Screen sharing:** If you have mods installed that change anything on-screen, anyone looking at the screen will be able to tell it's not vanilla.

  **Examples:** Minimaps; waypoints; indicators; menus of any kind; etc.

As a result, this mod is most useful for players that **develop their own modifications** with raw Mixin and without depending on Fabric API. It does **not** insulate between a detectable mod and the detection; all it does is prevent the client from admitting **up front** that it is Fabric.

### Notes on hiding mods from clients

Many of the same rules apply, though clients are likely to be less of a risk to a server than the other way around. Still, hiding the fact that a server is modded may still be desirable in some cases.

---

I accept issues and review pull requests.
